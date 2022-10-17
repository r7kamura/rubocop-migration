# frozen_string_literal: true

require 'rubocop'
require 'rubocop/migration'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.disable_monkey_patching!

  config.raise_errors_for_deprecations!

  config.raise_on_warning = true

  config.filter_run_when_matching :focus
end
