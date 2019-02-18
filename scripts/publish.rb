manifest_path = File.expand_path('../../app.json', __FILE__)
version = JSON.parse(File.read(manifest_path))['version']

exec("gem build opencensus-jaeger.gemspec && curl -F package=@opencensus-jaeger-#{version}.gem https://#{ENV['GEMFURY_TOKEN']}@push.fury.io/#{ENV['GEMFURY_PACKAGE']}/")
