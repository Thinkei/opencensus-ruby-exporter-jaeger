require 'socket'
require 'thrift'
require 'opencensus/trace/exporters/jaeger_driver/intermediate_transport'
require 'opencensus/trace/exporters/jaeger_driver/udp_sender'

module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        extend self

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

        def encode_span(span)
          tags = build_thrift_tags(span.attributes)
          trace_id_high = base16_hex_to_int64(
            span.trace_id.slice(0, 16)
          )
          trace_id_low = base16_hex_to_int64(
            span.trace_id.slice(16)
          )
          span_id = base16_hex_to_int64(
            span.span_id
          )
          parent_span_id = base16_hex_to_int64(
            span.parent_span_id
          )
          operation_name = span.name.value
          references = []
          flags = 0x01
          start_time = span.start_time.to_f * 1_000_000
          end_time = span.end_time.to_f * 1_000_000
          duration = end_time - start_time

          ::Jaeger::Thrift::Span.new(
            'traceIdLow': trace_id_low,
            'traceIdHigh': trace_id_high,
            'spanId': span_id,
            'parentSpanId': parent_span_id,
            'operationName': operation_name,
            'references': references,
            'flags': flags,
            'startTime': start_time,
            'duration': duration,
            'tags': tags
          )
        rescue StandardError => e
          puts "convert error #{e}"
        end

        def ip_v4
          ip_v4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
          ip_v4.nil? ? nil : ip_v4.ip_address
        end

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
