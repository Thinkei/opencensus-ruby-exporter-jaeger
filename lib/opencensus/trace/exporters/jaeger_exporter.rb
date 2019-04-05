require 'opencensus/trace/exporters/jaeger_driver'

module OpenCensus
  module Trace
    module Exporters
      class JaegerExporter
        include ::Logging
        JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY = 'opencensus.exporter.jaeger.version'.freeze
        TRACER_HOSTNAME_TAG_KEY = 'opencensus.exporter.jaeger.hostname'.freeze
        PROCESS_IP = 'ip'.freeze
        DEFAULT_MAX_LENGTH = 65_000

        attr_reader :client, :span_batches

        def initialize(
          logger: default_logger,
          service_name: 'UNCONFIGURED_SERVICE_NAME',
          host: 'localhost',
          port: 6831,
          tags: {},
          protocol_class: ::Thrift::CompactProtocol
        )
          @logger = logger
          @service_name = service_name
          @host = host
          @port = port

          default_tags = {}
          default_tags[JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY] = \
            "opencensus-exporter-jaeger-#{OpenCensus::Jaeger::VERSION}"
          default_tags[TRACER_HOSTNAME_TAG_KEY] = Socket.gethostname
          default_tags[PROCESS_IP] = JaegerDriver.ip_v4
          @tags = default_tags.merge(tags)
          @client = JaegerDriver::UDPSender.new(host, port, logger, protocol_class)
          @process = ::Jaeger::Thrift::Process.new(
            'serviceName': @service_name,
            'tags': JaegerDriver::Utils.build_thrift_tags(@tags)
          )
          @protocol_class = protocol_class
        end

        def export(spans)
          return nil if spans.nil? || spans.empty?
          export_as_batch(spans)
        rescue StandardError => e
          @logger.error("Fail to export spans due to #{e.message}")
        end

        def export_as_batch(spans)
          @logger.debug "Sending #{spans.inspect}"
          @span_batches = encode_within_limit(spans)
          @span_batches.each do |span_batch|
            @client.send_spans(span_batch)
          end
        end

        def encode_within_limit(spans)
          batches = []
          current_batch = []
          current_batch_size = 0

          spans.each do |span|
            encoded_span = JaegerDriver.encode_span(span)
            encoded_span_size = calculate_span_size(encoded_span)
            if encoded_span_size + current_batch_size >= DEFAULT_MAX_LENGTH && !current_batch.empty?
              batches << encode_batch(current_batch)
              current_batch = []
              current_batch_size = 0
            end
            current_batch << encoded_span
            current_batch_size += encoded_span_size
          end

          batches << encode_batch(current_batch) unless current_batch.empty?
          batches
        end

        def encode_batch(encoded_spans)
          ::Jaeger::Thrift::Batch.new(
            'process' => @process,
            'spans' => encoded_spans
          )
        end

        private

        def calculate_span_size(span)
          # https://github.com/apache/thrift/blob/master/lib/rb/lib/thrift/struct.rb#L95
          transport = JaegerDriver::IntermediateTransport.new
          protocol = @protocol_class.new(transport)
          span.write(protocol)
          transport.size
        end
      end
    end
  end
end
