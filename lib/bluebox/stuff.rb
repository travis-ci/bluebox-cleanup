require 'fog'

module Bluebox
  module Stuff
    private

    def bluebox_client
      @bluebox_client ||= build_bluebox_client
    end

    def build_bluebox_client
      Fog::Compute.new(
        provider: 'Bluebox',
        bluebox_customer_id: {
          'org' => ENV['BLUEBOX_ORG_ID'],
          'com' => ENV['BLUEBOX_COM_ID']
        }.fetch(site),
        bluebox_api_key: {
          'org' => ENV['BLUEBOX_ORG_API_KEY'],
          'com' => ENV['BLUEBOX_COM_API_KEY']
        }.fetch(site)
      )
    end

    def site
      argv.first || (ENV['BLUEBOX_ACCOUNT'] || 'org')
    end

    def argv
      ARGV
    end
  end
end
