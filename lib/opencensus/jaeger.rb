require 'opencensus'

module OpenCensus
end

thrift_folder = File.expand_path(__dir__ + '../../../thrift/gen-rb')
$LOAD_PATH.unshift(thrift_folder) unless $LOAD_PATH.include?(thrift_folder)

require 'jaeger/thrift/agent'
require 'opencensus/jaeger/version'
require 'opencensus/logging'
require 'opencensus/trace/exporters/jaeger_exporter'
