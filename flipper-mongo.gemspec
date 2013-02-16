# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/adapters/mongo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "flipper-mongo"
  gem.version       = Flipper::Adapters::Mongo::VERSION
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.description   = %q{Mongo adapter for Flipper}
  gem.summary       = %q{Mongo adapter for Flipper}
  gem.homepage      = "http://jnunemaker.github.com/flipper-mongo"
  gem.require_paths = ["lib"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.add_dependency 'flipper', '~> 0.4'
  gem.add_dependency 'mongo', '~> 1.8.0'
end
