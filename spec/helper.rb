$:.unshift(File.expand_path('../../lib', __FILE__))

require 'bundler'

Bundler.setup :default

require 'flipper-mongo'

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true
  config.fail_fast = true

  config.backtrace_clean_patterns = [
    /rspec-(core|expectations)/,
  ]
end
