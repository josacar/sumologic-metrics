lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sumologic/metrics/version'

Gem::Specification.new do |spec|
  spec.name          = 'sumologic-metrics'
  spec.version       = Sumologic::Metrics::VERSION
  spec.authors       = ['Jose Luis Salas']
  spec.email         = ['josacar@users.noreply.github.com']

  spec.summary       = 'Sumologic metrics worker'
  spec.description   = 'Send metrics to Sumologic in the background in batches'
  spec.homepage      = 'https://github.com/josacar/sumologic-metrics'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.16'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rspec', '~> 3.8'

  spec.required_ruby_version = '>= 2.4.0'
end
