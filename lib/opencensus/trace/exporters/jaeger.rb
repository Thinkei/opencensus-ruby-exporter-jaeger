require 'concurrent-ruby'
require 'jaeger/client'
require 'socket'

module OpenCensus
  module Trace
    module Exporters
      class Jaeger
        include ::Logging

        JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY = 'opencensus.exporter.jaeger.version'.freeze
        TRACER_HOSTNAME_TAG_KEY = 'opencensus.exporter.jaeger.hostname'.freeze
        PROCESS_IP = 'ip'.freeze

        def initialize(
          logger: nil,
          service_name: nil,
          host: 'localhost',
          port: nil,
          tags: {},
          max_threads: 1,
          max_queue: 1000,
          auto_terminate_time: 10,
          flush_interval: nil
        )
          @logger = logger || default_logger
          @service_name = service_name
          @host = host
          @port = port
          @flush_interval = @flush_interval
          default_tags = {
            'JAEGER_VERSION': "ruby-#{::Jaeger::Client::VERSION}",
            'TRACER_HOSTNAME': Socket.gethostname,
            'PROCESS_IP': ip_v4
          }
          @tags = tags.merge(default_tags)
          @executor = create_executor(max_threads, max_queue)
          if auto_terminate_time
            terminate_at_exit!(@executor, auto_terminate_time)
          end

          @client_config = {
            host: @host,
            port: @port,
            logger: @logger
          }
          @client_promise = create_client_promise(@executor, @client_config)
        end

        def export(spans)
          raise 'Executor is no longer running' unless @executor.running?
          return nil if spans.nil? || spans.empty?
          @client_promise.execute
          export_promise = @client_promise.then do |client|
            export_as_batch(client, spans)
          end
          export_promise.on_error do |error|
            @logger.warn "Unable to export to Jaeger because of: #{error}. Backtrace: #{error.backtrace}"
          end
        end

        private

        def ip_v4
          ipv4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
          ipv4.nil? ? nil : ipv4.ip_address
        end

        def export_as_batch(client, spans)
          @logger.info "Sending #{spans.inspect}"
          jaeger_spans = Array(spans).map do |span|
            JaegerDriver::Converter.convert(span)
          end
          spans_batch = ::Jaeger::Thrift::Batch.new(
            'process' => ::Jaeger::Thrift::Process.new(
              'serviceName': @service_name,
              'tags': JaegerDriver::Utils.build_thrift_tags(@tags)
            ),
            'spans' => jaeger_spans
          )
          client.send_spans(spans_batch)
        end

        def create_client(client_config)
          JaegerDriver::UdpSender.new(client_config)
        end

        def create_executor(max_threads, max_queue)
          if max_threads >= 1
            Concurrent::ThreadPoolExecutor.new(
              min_threads: 1, max_threads: max_threads,
              max_queue: max_queue, fallback_policy: :caller_runs,
              auto_terminate: false
            )
          else
            Concurrent::ImmediateExecutor.new
          end
        end

        def terminate_at_exit!(executor, timeout)
          at_exit do
            @logger.info('ThreadPoolExecutor shutdown!')
            executor.shutdown
            unless executor.wait_for_termination(timeout)
              executor.kill
              executor.wait_for_termination(timeout)
            end
          end
        end

        def create_client_promise(
          executor, client_config
        )
          Concurrent::Promise.new executor: executor do
            create_client(client_config)
          end
        end
      end
    end
  end
end
