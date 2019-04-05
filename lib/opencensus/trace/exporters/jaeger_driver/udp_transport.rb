module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class UDPTransport
          FLAGS = 0

          def initialize(host, port, logger)
            @socket = UDPSocket.new
            @host = host
            @port = port
            @logger = logger
            @buffer = ::Thrift::MemoryBufferTransport.new
          end

          def write(str)
            @buffer.write(str)
          end

          def flush
            data = @buffer.read(@buffer.available)
            send_bytes(data)
          end

          def open; end

          def close; end

          private

          def send_bytes(bytes)
            @socket.send(bytes, FLAGS, @host, @port)
            @socket.flush
          rescue Errno::ECONNREFUSED
            @logger.warn 'Unable to connect to Jaeger Agent'
          rescue Errno::EMSGSIZE
            @logger.error 'Unable to send span due to UDP max size'
          rescue StandardError => e
            @logger.warn "Unable to send spans: #{e.message}"
          end
        end
      end
    end
  end
end
