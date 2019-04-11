require 'spec_helper'

RSpec::Matchers.define :be_a_valid_span do |_|
  match do |actual|
    actual.instance_of?(::Jaeger::Thrift::Span) &&
      !actual.instance_variable_get(:@traceIdLow).nil? &&
      !actual.instance_variable_get(:@traceIdHigh).nil? &&
      !actual.instance_variable_get(:@spanId).nil? &&
      !actual.instance_variable_get(:@parentSpanId).nil? &&
      !actual.instance_variable_get(:@operationName).nil? &&
      !actual.instance_variable_get(:@flags).nil? &&
      !actual.instance_variable_get(:@startTime).nil? &&
      !actual.instance_variable_get(:@duration).nil? &&
      !actual.instance_variable_get(:@tags).nil?
  end
end

describe OpenCensus::Trace::Exporters::JaegerExporter do
  describe '.export' do
    let(:exporter) { described_class.new(service_name: 'test_service') }
    let(:root_context) { OpenCensus::Trace::SpanContext.create_root }
    let(:span_builder) { root_context.start_span "hello" }
    let(:span_builder2) { span_builder.context.start_span "world" }

    before do
      span_builder2.finish!
      span_builder.finish!
    end

    context 'when spans exist' do
      context 'when spans dont exceed spans limit' do
        let(:spans) { [span_builder.to_span, span_builder2.to_span] }
        it 'encode spans to jaeger format and call client to send spans' do
          expect(exporter.client).to receive(:send_spans).and_call_original.with instance_of(::Jaeger::Thrift::Batch)
          exporter.export(spans)
          expect(exporter.span_batches.length).to eql(1)
          expect(exporter.span_batches.first.spans.first).to be_a_valid_span
          expect(exporter.span_batches.first.spans.last).to be_a_valid_span
        end
      end

      context 'when spans have big size' do
        let(:spans) { [] }
        let(:spans_length) { 1200 } # each span has size at about 55kb so this should exceeds the limit

        before do
          spans_length.times { spam_span = root_context.start_span "duplicate"; spam_span.finish!; spans << spam_span.to_span }
        end

        it 'encode spans to jaeger format and call client to send spans' do
          expect(exporter.client).to receive(:send_spans).and_call_original.exactly(:twice).with instance_of(::Jaeger::Thrift::Batch)
          exporter.export(spans)
          expect(exporter.span_batches.length).to eql(2) # it exceeds limit only once
          expect(exporter.span_batches.first.spans.first).to be_a_valid_span
          expect(exporter.span_batches.first.spans.last).to be_a_valid_span
          expect(exporter.span_batches.last.spans.first).to be_a_valid_span
          expect(exporter.span_batches.last.spans.first).to be_a_valid_span
        end
      end

      context 'when spans are empty' do
        let(:empty_spans) { [] }
        it 'returns nil and do nothing' do
          expect(exporter).to_not receive(:export_as_batch)
          exported_spans = exporter.export(empty_spans)
          expect(exported_spans).to be_nil
        end
      end
    end
  end

  describe '.encode_batch' do
    let(:exporter) { described_class.new(service_name: 'Test', tags: input_tags) }

    context 'without custom tags' do
      let(:input_tags) { {} }

      it 'has opencensus-exporter-jaeger-version' do
        tags = exporter.encode_batch([]).process.tags
        version_tag = tags.detect { |tag| tag.key == described_class::JAEGER_OPENCENSUS_EXPORTER_VERSION_TAG_KEY }
        expect(version_tag.vStr).to match(/opencensus-exporter-jaeger-/)
      end

      it 'has hostname' do
        tags = exporter.encode_batch([]).process.tags
        hostname_tag = tags.detect { |tag| tag.key == described_class::TRACER_HOSTNAME_TAG_KEY }
        expect(hostname_tag.vStr).to be_a(String)
      end

      it 'has ip' do
        tags = exporter.encode_batch([]).process.tags
        ip_tag = tags.detect { |tag| tag.key == described_class::PROCESS_IP }
        expect(ip_tag.vStr).to be_a(String)
      end
    end

    context 'when hostname is provided' do
      let(:input_tags) { { 'opencensus.exporter.jaeger.hostname' => hostname } }
      let(:hostname) { 'custom-hostname' }

      it 'uses provided hostname in the process tags' do
        tags = exporter.encode_batch([]).process.tags
        hostname_tag = tags.detect { |tag| tag.key == described_class::TRACER_HOSTNAME_TAG_KEY }
        expect(hostname_tag.vStr).to eq(hostname)
      end
    end

    context 'when ip is provided' do
      let(:input_tags) { { 'ip' => ip } }
      let(:ip) { 'custom-ip' }

      it 'uses provided ip in the process tags' do
        tags = exporter.encode_batch([]).process.tags
        ip_tag = tags.detect { |tag| tag.key == described_class::PROCESS_IP }
        expect(ip_tag.vStr).to eq(ip)
      end
    end
  end
end
