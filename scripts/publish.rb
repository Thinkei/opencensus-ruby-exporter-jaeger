lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opencensus/jaeger/version'

version = OpenCensus::Jaeger::VERSION

exec("gem build opencensus-jaeger.gemspec && curl -F package=@opencensus-jaeger-#{version}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
