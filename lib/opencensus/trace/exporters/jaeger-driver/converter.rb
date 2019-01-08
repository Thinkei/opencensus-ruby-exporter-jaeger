require 'jaeger/tracer'
require 'jaeger/trace_id'
require 'jaeger/thrift_tag_builder'

module Opencensus
  module Trace
    module Exporters
      class JaegerDriver
        class Converter
          def initialize
            @tags = {}
          end

          def convert span
            @tags.merge! span.attributes
            @tags.merge! span.tags
            trace_id_high = span.trace_id.slice(0, 16)
            trace_id_low = span.trace_id.slice(16)
            span_id = span.span_id
            parent_span_id = span.parent_span_id
            operation_name = span.name
            references = []
            flags = 0x01
            start_time = span.start_time.to_f * 1_000_000
            end_time = span.end_time.to_f * 1_000_000
            duration = end_time - start_time

            return {
              'traceIdLow': base16_hex_to_int64(trace_id_low),
              'traceIdHigh': base16_hex_to_int64(trace_id_high),
              'spanId': base16_hex_to_int64(span_id),
              'parentSpanId': base16_hex_to_int64(parent_span_id),
              'operationName': operation_name,
              'references': references,
              'flags': flags,
              'startTime': string_to_int64(start_time),
              'duration': string_to_int64(duration),
              'tags': build_thrift_tags(@tags)
            }
          end

          private

          def base16_hex_to_int64 id
            ::Jarger::TraceId.uint64_id_to_int64(::Jaeger::TraceId.base16_hex_id_to_uint64 id)
          end

          def string_to_int64 id
            id_as_hex = ::Jaeger::TraceId.to_hex(id)
            base16_hex_to_int64 id_as_hex
          end

          def build_thrift_tags tags
            tags.map do |key, value|
              ::Jaeger::ThriftTagBuilder.build(key, value)
            end
          end
        end
      end
    end
  end
end
