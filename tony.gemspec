# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tony/version'

Gem::Specification.new do |spec|
  spec.name          = 'tony'
  spec.version       = Tony::VERSION
  spec.authors       = ['Justin Piotroski']
  spec.email         = ['justin.piotroski@gmail.com']

  spec.summary       = 'A Virtual Intelligence interface for the scheduling, execution, and automation of tasks'
  spec.homepage      = 'https://github.com/jtp184/tony'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Development Dependencies
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5'

  # Runtime Dependencies
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'twilio-ruby'
end
