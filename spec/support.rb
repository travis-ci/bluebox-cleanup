require 'simplecov'
require 'bluebox'

def integration?
  ENV['INTEGRATION_SPECS'] == '1'
end

RSpec.configure do |c|
  c.filter_run_excluding(integration: true) unless integration?
end
