require 'socket'
require 'jaeger/client'
require 'concurrent-ruby'

module Opencensus
  module Trace
    module Exporters
      class Jaeger
        include Logging
        JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY = 'opencensus.exporter.jaeger.version'
        TRACER_HOSTNAME_TAG_KEY = 'opencensus.exporter.jaeger.hostname'
        PROCESS_IP = 'ip'

        def initialize \
            logger: nil,
            service_name: nil,
            host: 'localhost',
            port: nil,
            tags: nil,
            max_threads: 1,
            max_queue: 1000,
            auto_terminate_time: 10,
            flush_interval: nil

          @logger = logger || default_logger
          @service_name = service_name
          @host = host
          @port = port
          @flush_interval = @flush_interval
          @default_tags = {}
          @default_tags[JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY] = "opencensus-exporter-jaeger-#{Jaeger::VERSION}"
          @default_tags[TRACER_HOSTNAME_TAG_KEY] = Socket.gethostname
          @default_tags[PROCESS_IP] = get_ip_v4 unless get_ip_v4.nil?
          @tags = @default_tags.merge tags

          @executor = create_executor max_threads, max_queue
          if auto_terminate_time
            terminate_at_exit! @executor, auto_terminate_time
          end

          @client_config = {
            host: @host,
            port: @port,
            service_name: @service_name,
            logger: @logger,
            flush_interval: @flush_interval,
            tags: @tags
          }
          @client_promise = create_client_promise @executor, @client_config
        end

        def export spans
          raise 'Executor is no longer running' unless @executor.running?
          return nil if span.nil? || spans.empty?

          @client_promise.execute
          export_promise = @client_promise.then do |client|
            export_as_batch
          end
        end

        private

        def export_as_batch client, spans
          # do converting and export to jaeger
        end

        def get_ip_v4
          ipv4 = Socket.ip_address_list.find do |ai|
            ai.ipv4 && !ai.ipv4.loopback?
          end
          ipv4.nil? ? nil : ipv4.ip_address
        end

        def create_client client_config
          ::Jaeger::Client.build client_config
        end

        def create_executor max_threads, max_queue
          if max_threads >= 1
            Concurrent::ThreadPoolExecutor.new \
              min_threads: 1, max_threads: max_threads,
              max_queue: max_queue, fallback_policy: :caller_runs,
              auto_terminate: false
          else
            Concurrent::ImmediateExecutor.new
          end
        end

        def terminate_at_exit! executor, timeout
          at_exit do
            executor.shutdown
            unless executor.wait_for_termination timeout
              executor.kill
              executor.wait_for_termination timeout
            end
          end
        end

        def create_client_promise \
            executor, client_config
          Concurrent::Promise.new executor: executor do
            create_client client_config
          end
        end
      end
    end
  end
end
