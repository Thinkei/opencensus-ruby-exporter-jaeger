# frozen_string_literal: true

module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class IntermediateTransport
          attr_accessor :size

          def initialize
            @size = 0
          end

          def write(buf)
            @size += buf.size
          end

          def flush
            @size = 0
          end

          def close; end
        end
      end
    end
  end
end
