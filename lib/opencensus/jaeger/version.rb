module OpenCensus
  module Jaeger
    manifest_path = File.expand_path('../../../app.json', __dir__)
    VERSION = JSON.parse(File.read(manifest_path))['version']
  end
end
