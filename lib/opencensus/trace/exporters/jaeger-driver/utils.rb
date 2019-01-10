require 'jaeger/span/thrift_tag_builder'

module Opencensus
  module Trace
    module Exporters
      module JaegerDriver
        class Utils
          include ::Logging

          MAX_64BIT_SIGNED_INT = (1 << 63) - 1
          MAX_64BIT_UNSIGNED_INT = (1 << 64) - 1
          TRACE_ID_UPPER_BOUND = MAX_64BIT_UNSIGNED_INT + 1

          class << self
            def base16_hex_id_to_uint64(id)
              return nil unless id
              value = id.to_i(16)
              value > MAX_64BIT_UNSIGNED_INT || value < 0 ? 0 : value
            end

            # Thrift defines ID fields as i64, which is signed, therefore we convert
            # large IDs (> 2^63) to negative longs
            def uint64_id_to_int64(id)
              id > MAX_64BIT_SIGNED_INT ? id - MAX_64BIT_UNSIGNED_INT - 1 : id
            end

            def base16_hex_to_int64(id)
              uint64_id = base16_hex_id_to_uint64(id)
              uint64_id_to_int64(uint64_id)
            end

            def build_thrift_tags(attributes)
              attributes.collect do |k, v|
                begin
                  if v.instance_of?(OpenCensus::Trace::TruncatableString)
                    ::Jaeger::Span::ThriftTagBuilder.build(k, v.value)
                  else
                    ::Jaeger::Span::ThriftTagBuilder.build(k, v)
                  end
                rescue StandardError => error
                  logger.error "Cannot build thrift tags for #{k}:#{v}, error: #{error}"
                end
              end
            end
          end
        end
      end
    end
  end
end
