# -*- encoding: utf-8 -*-
require File.expand_path('../lib/flipper/adapters/mongo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Nunemaker"]
  gem.email         = ["nunemaker@gmail.com"]
  gem.description   = %q{Mongo adapter for Flipper}
  gem.summary       = %q{Mongo adapter for Flipper}
  gem.homepage      = "http://jnunemaker.github.com/flipper-mongo"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "flipper-mongo"
  gem.require_paths = ["lib"]
  gem.version       = Flipper::Adapters::Mongo::VERSION
  gem.add_dependency 'flipper', '~> 0.1.1'
end
