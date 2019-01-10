require 'jaeger/tracer'
require_relative './utils'

module Opencensus
  module Trace
    module Exporters
      module JaegerDriver
        class Converter
          class << self
            def convert span
              tags = Utils.build_thrift_tags span.attributes
              trace_id_high = Utils.base16_hex_to_int64(
                span.trace_id.slice(0, 16)
              )
              trace_id_low = Utils.base16_hex_to_int64(
                span.trace_id.slice(16)
              )
              span_id = Utils.base16_hex_to_int64(
                span.span_id
              )
              parent_span_id = Utils.base16_hex_to_int64(
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
            end
          end
        end
      end
    end
  end
end
