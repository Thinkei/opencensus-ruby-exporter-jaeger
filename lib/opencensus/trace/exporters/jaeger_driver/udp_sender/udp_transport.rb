module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class UdpSender
          class UdpTransport
            FLAGS = 0
            DEFAULT_UDP_SIZE = 65536 # 64kb
            MIN_UDP_SIZE = 512 # 512 bytes

            class << self
              def udp_max_size
                @udp_max_size ||= DEFAULT_UDP_SIZE
              end

              def can_adjust_udp_max?
                udp_max_size / 2 >= MIN_UDP_SIZE
              end

              def adjust_udp_max_size!
                if can_adjust_udp_max?
                  @udp_max_size /= 2
                end
              end
            end

            def initialize(host:, port:, logger:)
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
              @logger.debug "Send UDP diagram of size #{bytes.bytesize}, batch size: #{self.class.udp_max_size}"
              begin
                if bytes.bytesize > self.class.udp_max_size
                  bytes.bytes.each_slice(self.class.udp_max_size) do |batch|
                    @socket.send(batch.pack('C*'), FLAGS, @host, @port)
                    @socket.flush
                  end
                else
                  @socket.send(bytes, FLAGS, @host, @port)
                  @socket.flush
                end
              rescue Errno::ECONNREFUSED
                @logger.warn 'Unable to connect to Jaeger Agent'
              rescue Errno::EMSGSIZE
                if self.class.can_adjust_udp_max?
                  self.class.adjust_udp_max_size!
                  @logger.warn "Adjust UDP batch size: #{self.class.udp_max_size}"
                  retry
                else
                  @logger.error 'Unable to send span due to UDP max size. Give up!'
                end
              rescue StandardError => e
                @logger.warn "Unable to send spans: #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
