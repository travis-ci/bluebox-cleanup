require 'travis/config'

module Bluebox
  def config
    @config ||= Config.load
  end

  module_function :config

  class Config < Travis::Config
    define(
      logger: {
        process_id: true, thread_id: true, format_type: 'l2met'
      },
      log_level: :info
    )

    default(_access: [:key])
  end
end
