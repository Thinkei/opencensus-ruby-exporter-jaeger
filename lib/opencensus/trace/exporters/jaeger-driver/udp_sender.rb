require 'jaeger/udp_sender/transport'
require 'thrift'

module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class UdpSender
          include ::Logging

          def initialize(
            host: nil,
            port: nil,
            logger: nil
          )
            @logger = logger || default_logger
            @host = host
            @port = port

            transport = ::Jaeger::UdpSender::Transport.new(host, port)
            protocol = ::Thrift::CompactProtocol.new(transport)
            @client = ::Jaeger::Thrift::Agent::Client.new(protocol)
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
