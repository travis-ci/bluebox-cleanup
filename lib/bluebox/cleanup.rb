require 'fog'
require 'hurley'

require_relative 'cleanup_runner'

module Bluebox
  class Cleanup
    def self.main(argv = ARGV)
      new(argv).run
    end

    USAGE = <<-EOF.gsub(/^\s+> ?/, '')
      > Usage: #{File.basename($PROGRAM_NAME)} [account-alias]
      >
      > Environment variables:
      >              BLUEBOX_API_KEY - [REQUIRED] account api key
      >      BLUEBOX_CLEANUP_FOREVER - run on repeat
      >   BLUEBOX_CLEANUP_LOOP_SLEEP - sleep interval when running forever
      >          BLUEBOX_CUSTOMER_ID - [REQUIRED] account customer id
      >         TRAVIS_JOB_STATE_URL - [REQUIRED] URL to the job-state API
      >
      > The above key may be found at:
      >   https://boxpanel.bluebox.net/public/bp/api
      >
      > When we are refreshing workers on Blue Box, often the blocks are
      > left stale as the controlling worker is destroyed without cleaning
      > up the job runners.
      >
      > You can delete these stale blocks by checking the job id of the
      > block and comparing that with the job status, then clicking on
      > "Destroy" button, and confirming the popup dialog box.
      > This is cumbersome.
      >
      > This script gets the list of blocks running tests, and destroy
      > them if our API says the job it was running has finished.
    EOF

    attr_reader :argv

    def initialize(argv = ARGV)
      @argv = argv
    end

    def run
      if argv.first.to_s =~ /-h|--help|help|wat/
        puts USAGE
        return 0
      end

      %w(
        BLUEBOX_API_KEY
        BLUEBOX_CUSTOMER_ID
        TRAVIS_JOB_STATE_URL
      ).each do |key|
        next if ENV.key?(key)
        puts USAGE
        puts "ERROR: Missing #{key.inspect}"
        return 1
      end

      sleep_seconds = Integer(ENV['BLUEBOX_CLEANUP_LOOP_SLEEP'] || 60)

      runner = Bluebox::CleanupRunner.new(
        batch_size: batch_size,
        travis_client: travis_client,
        bluebox_client: bluebox_client
      )

      loop do
        runner.run
        break unless ENV['BLUEBOX_CLEANUP_FOREVER']

        log.info('sleeping', seconds: sleep_seconds)
        sleep sleep_seconds
      end

      0
    end

    private

    def batch_size
      @batch_size ||= Integer(ENV['BLUEBOX_CLEANUP_BATCH_SIZE'] || 20)
    end

    def travis_client
      @travis_client ||= build_travis_client
    end

    def build_travis_client
      Hurley::Client.new(travis_job_state_url).tap do |client|
        client.header[:accept] = 'application/json'
      end
    end

    def travis_job_state_url
      ENV.fetch('TRAVIS_JOB_STATE_URL')
    end

    def bluebox_client
      @bluebox_client ||= build_bluebox_client
    end

    def build_bluebox_client
      Fog::Compute.new(
        provider: 'Bluebox',
        bluebox_customer_id: ENV['BLUEBOX_CUSTOMER_ID'],
        bluebox_api_key: ENV['BLUEBOX_API_KEY']
      )
    end

    def log
      ::Bluebox.logger
    end
  end
end
