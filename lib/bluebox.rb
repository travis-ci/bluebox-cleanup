require_relative 'travis'

module Bluebox
  autoload :Cleanup, 'bluebox/cleanup'
  autoload :CleanupRunner, 'bluebox/cleanup_runner'
  autoload :Config, 'bluebox/config'

  def logger
    Travis.logger
  end

  module_function :logger
end
