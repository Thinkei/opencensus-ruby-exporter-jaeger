# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opencensus/jaeger/version'

Gem::Specification.new do |spec|
  spec.name          = 'opencensus-jaeger'
  spec.version       = OpenCensus::Jaeger::VERSION
  spec.authors       = ['Luong Vo']
  spec.email         = ['vo.tran.thanh.luong@gmail.com']

  spec.summary       = 'Jaeger exporter for OpenCensus'
  spec.description   = 'Jaeger exporter for OpenCensus'
  spec.homepage      = 'https://www.github.com/Thinkei/opencensus-ruby-exporter-jaeger'
  spec.license       = 'Apache-2.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
    #
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = 'https://github.com/Thinkei/opencensus-ruby-exporter-jaeger/blob/master/CHANGELOG.md'
    # else
    #   raise "RubyGems 2.0 or newer is required to protect against " \
    #     "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'opencensus', '~> 0.5.0'
  spec.add_dependency 'thrift', '~> 0.11.0'

  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
