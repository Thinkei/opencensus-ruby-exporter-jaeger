module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        class Utils
          include ::Logging

          MAX_64BIT_SIGNED_INT = (1 << 63) - 1
          MAX_64BIT_UNSIGNED_INT = (1 << 64) - 1
          TRACE_ID_UPPER_BOUND = MAX_64BIT_UNSIGNED_INT + 1

          FIELDS = ::Jaeger::Thrift::Tag::FIELDS
          KEY = FIELDS[::Jaeger::Thrift::Tag::KEY].fetch(:name)
          VTYPE = FIELDS[::Jaeger::Thrift::Tag::VTYPE].fetch(:name)
          VLONG = FIELDS[::Jaeger::Thrift::Tag::VLONG].fetch(:name)
          VDOUBLE = FIELDS[::Jaeger::Thrift::Tag::VDOUBLE].fetch(:name)
          VBOOL = FIELDS[::Jaeger::Thrift::Tag::VBOOL].fetch(:name)
          VSTR = FIELDS[::Jaeger::Thrift::Tag::VSTR].fetch(:name)

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
              attributes.collect do |key, value|
                begin
                  if value.is_a?(OpenCensus::Trace::TruncatableString)
                    ::Jaeger::Thrift::Tag.new(
                      KEY => key.to_s,
                      VTYPE => ::Jaeger::Thrift::TagType::STRING,
                      VSTR => value.value
                    )
                  elsif value.is_a?(Integer)
                    ::Jaeger::Thrift::Tag.new(
                      KEY => key.to_s,
                      VTYPE => ::Jaeger::Thrift::TagType::LONG,
                      VLONG => value
                    )
                  elsif value.is_a?(Float)
                    ::Jaeger::Thrift::Tag.new(
                      KEY => key.to_s,
                      VTYPE => ::Jaeger::Thrift::TagType::DOUBLE,
                      VDOUBLE => value
                    )
                  elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                    ::Jaeger::Thrift::Tag.new(
                      KEY => key.to_s,
                      VTYPE => ::Jaeger::Thrift::TagType::BOOL,
                      VBOOL => value
                    )
                  else
                    ::Jaeger::Thrift::Tag.new(
                      KEY => key.to_s,
                      VTYPE => ::Jaeger::Thrift::TagType::STRING,
                      VSTR => value.to_s
                    )
                  end
                rescue StandardError => error
                  logger.error "Cannot build thrift tags for #{key}:#{value}, error: #{error}"
                end
              end
            end
          end
        end
      end
    end
  end
end
