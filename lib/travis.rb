require 'travis/support'

module Travis
  def config
    require 'bluebox/config'
    ::Bluebox.config
  end

  module_function :config
end
