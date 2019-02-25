require 'opencensus'

module OpenCensus
end

thrift_folder = File.expand_path(__dir__ + '../../../thrift/gen-rb')
$LOAD_PATH.unshift(thrift_folder) unless $LOAD_PATH.include?(thrift_folder)

require 'jaeger/thrift/agent'
require 'opencensus/jaeger/version'
require 'opencensus/logging'
require 'opencensus/trace/exporters/jaeger'
require 'opencensus/trace/exporters/jaeger_driver/converter'
require 'opencensus/trace/exporters/jaeger_driver/udp_sender'
require 'opencensus/trace/exporters/jaeger_driver/udp_sender/udp_transport'
require 'opencensus/trace/exporters/jaeger_driver/utils'
