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
          tags: {}
        )
          @logger = logger || default_logger
          @service_name = service_name
          @host = host
          @port = port
          default_tags = {}
          default_tags[JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY] = \
            "opencensus-exporter-jaeger-#{OpenCensus::Jaeger::VERSION}"
          default_tags[TRACER_HOSTNAME_TAG_KEY] = Socket.gethostname
          default_tags[PROCESS_IP] = ip_v4
          @tags = tags.merge(default_tags)

          @client_config = {
            host: @host,
            port: @port,
            logger: @logger
          }
          @client = create_client(@client_config)
        end

        def export(spans)
          return nil if spans.nil? || spans.empty?
          export_as_batch(@client, spans)
        rescue => e
          @logger.error("Fail to export spans due to #{e.message}")
        end

        private

        def ip_v4
          ipv4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
          ipv4.nil? ? nil : ipv4.ip_address
        end

        def export_as_batch(client, spans)
          @logger.debug "Sending #{spans.inspect}"
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
      end
    end
  end
end
