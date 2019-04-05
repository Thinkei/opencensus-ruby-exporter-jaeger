require 'opencensus/trace/exporters/jaeger_driver/udp_transport'

module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class UDPSender
          include ::Logging

          def initialize(host, port, logger, protocol_class)
            @logger = logger || default_logger
            @host = host
            @port = port
            @transport = UDPTransport.new(host, port, logger)
            @protocol = protocol_class.new(@transport)
            @client = ::Jaeger::Thrift::Agent::Client.new(@protocol)
          end

          def send_spans(spans)
            @client.emitBatch(spans)
          rescue StandardError => error
            @logger.error "Failure while sending a batch of spans: #{error}"
          end
        end
      end
    end
  end
end
