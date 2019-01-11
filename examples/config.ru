require 'opencensus/jaeger'
require 'opencensus/trace/integrations/rack_middleware'
require 'opencensus/trace/integrations/faraday_middleware'
require_relative './example.rb'

OpenCensus.configure do |c|
  c.trace.exporter = OpenCensus::Trace::Exporters::Jaeger.new \
    logger: nil,
    service_name: 'test_service',
    host: 'localhost',
    port: 6831,
    max_threads: 10,
    max_queue: 100,
    tags: { 'example_tag': 'hello_world' }
end

use OpenCensus::Trace::Integrations::RackMiddleware
run Example
