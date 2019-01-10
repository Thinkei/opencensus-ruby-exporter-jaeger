require 'jaeger/tracer'
require 'jaeger/span/thrift_tag_builder'
require_relative './utils'

module Opencensus
  module Trace
    module Exporters
      module JaegerDriver
        class Converter
          def initialize
            @tags = []
          end

          def convert span
            build_thrift_tags span.attributes
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

            ::Jaeger::Thrift::Span.new(
              'traceIdLow': base16_hex_to_int64(trace_id_low),
              'traceIdHigh': base16_hex_to_int64(trace_id_high),
              'spanId': base16_hex_to_int64(span_id),
              'parentSpanId': base16_hex_to_int64(parent_span_id),
              'operationName': operation_name,
              'references': references,
              'flags': flags,
              'startTime': start_time,
              'duration': duration,
              'tags': @tags
            )
          end

          private

          def base16_hex_to_int64 id
            uint64_id = Utils.base16_hex_id_to_uint64 id
            Utils.uint64_id_to_int64 uint64_id
          end

          def build_thrift_tags tags
            tags.each do |key, value|
              @tags << ::Jaeger::Span::ThriftTagBuilder.build(key, value)
            end
          end
        end
      end
    end
  end
end
