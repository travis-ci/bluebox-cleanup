require 'json'
require 'fog'
require 'hurley'

require_relative 'stuff'
require 'l2met_log'

module Bluebox
  class Cleanup
    include Stuff
    include L2metLog

    def self.main(argv = ARGV)
      new(argv).run
    end

    COMPLETED_STATES = %w(passed failed errored canceled).freeze

    USAGE = <<-EOF.gsub(/^ {4}/, '')
    Usage: #{File.basename($PROGRAM_NAME)} [account-alias]

    Environment variables:

      BLUEBOX_ORG_API_KEY - org account api key from https://boxpanel.bluebox.net/public/bp/api
      BLUEBOX_COM_API_KEY - com account api key from https://boxpanel.bluebox.net/public/bp/api

    When we are refreshing workers on Blue Box, often the blocks are left stale
    as the controlling worker is destroyed without cleaning up the job runners.

    You can delete these stale blocks by checking the job id of the block and comparing
    that with the job status, then clicking on "Destroy" button, and confirming the popup
    dialog box. This is cumbersome.

    This script gets the list of blocks running tests, and destroy them if our API
    says the job it was running has finished.
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

      unless [ENV.key?('BLUEBOX_ORG_API_KEY'), ENV.key?('BLUEBOX_COM_API_KEY')].any?
        puts USAGE
        return 1
      end

      run_forever if ENV['BLUEBOX_CLEANUP_FOREVER']
      run_once
    end

    def run_forever
      loop do
        run_once
        sleep Integer(ENV['BLUEBOX_CLEANUP_LOOP_SLEEP'] || 60)
      end
    end

    def run_once
      n_killed = 0
      n_batch = 0

      log(msg: 'fetching all bluebox servers', site: site)
      bluebox_client.servers.each_slice(batch_size) do |servers|
        log(msg: 'starting server batch', batch: n_batch)
        job_id_map = {}

        servers.each do |server|
          next unless server.hostname =~ /^testing-worker-linux/
          id = server.hostname.match(/-(\d+)\./)[1]
          job_id_map[id] = server
        end

        next if job_id_map.empty?

        begin
          states = JSON.parse(travis_client.get("/multi/#{job_id_map.keys.join(',')}").body)
          next if (states.nil? || states.empty? || states['data'].nil? || states['data'].empty?)
        rescue => e
          log(msg: 'failed to fetch job states', job_ids: job_id_map.keys, err: e, level: :error)
          next
        end

        states['data'].each do |job|
          log(msg: 'handling job', job_id: job['id'], job_state: job['state'])

          if COMPLETED_STATES.include?(job['state'])
            block_id = job_id_map[job['id']].id
            log(
              msg: "job is #{job['state']}, killing block",
              block_id: block_id,
              job_id: job['id'],
              job_state: job['state']
            )
            bluebox_client.request(
              method: 'DELETE',
              path: "/api/blocks/#{block_id}.js"
            )
            n_killed += 1
          end
        end

        n_batch += 1
      end

      log(msg: 'done', n_killed: n_killed, site: site)
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
      return ENV.fetch('TRAVIS_JOB_STATE_URL') if site == 'org'
      ENV.fetch('TRAVIS_PRO_JOB_STATE_URL')
    end
  end
end
