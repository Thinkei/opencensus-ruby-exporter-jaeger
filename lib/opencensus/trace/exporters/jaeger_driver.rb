require 'socket'
require 'thrift'
require 'opencensus/trace/exporters/jaeger_driver/intermediate_transport'
require 'opencensus/trace/exporters/jaeger_driver/udp_sender'
require 'opencensus/trace/exporters/jaeger_driver/utils'

module OpenCensus
  module Trace
    module Exporters
      module JaegerDriver
        extend self

        def encode_span(span)
          tags = Utils.build_thrift_tags(span.attributes)
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
        rescue StandardError => e
          puts "convert error #{e}"
        end

        def ip_v4
          ip_v4 = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }
          ip_v4.nil? ? nil : ip_v4.ip_address
        end
      end
    end
  end
end
