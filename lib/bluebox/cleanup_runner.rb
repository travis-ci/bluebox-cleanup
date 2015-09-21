require 'json'

module Bluebox
  class CleanupRunner
    COMPLETED_STATES = %w(passed failed errored canceled).freeze

    def initialize(batch_size: 20, travis_client: nil, bluebox_client: nil)
      @batch_size = batch_size
      @travis_client = travis_client
      @bluebox_client = bluebox_client
    end

    def run
      n_killed = 0
      n_batch = 0
      n_errors = 0

      log.info('fetching all bluebox servers')

      bluebox_client.servers.each_slice(batch_size) do |servers|
        log.info('starting server batch', batch: n_batch)
        job_id_map = {}

        servers.each do |server|
          next unless server.hostname =~ /^testing-worker-linux/
          id = server.hostname.match(/-(\d+)\./)[1]
          job_id_map[id] = server
        end

        next if job_id_map.empty?

        begin
          states = JSON.parse(
            travis_client.get("/multi/#{job_id_map.keys.join(',')}").body
          )
          next if states.nil? || states.empty? ||
                  states['data'].nil? || states['data'].empty?
        rescue => e
          log.error(
            'failed to fetch job states',
            job_ids: job_id_map.keys,
            err: "#{e}"
          )
          next
        end

        states['data'].each do |job|
          next unless COMPLETED_STATES.include?(job['state'])
          log.info('handling job', job_id: job['id'], job_state: job['state'])

          block_id = job_id_map[job['id']].id
          log.info(
            "job is #{job['state']}, killing block",
            block_id: block_id,
            job_id: job['id'],
            job_state: job['state']
          )

          begin
            bluebox_client.destroy_block(block_id)
            n_killed += 1
          rescue => e
            if e.respond_to?(:cause)
              err_msg = JSON.parse(e.cause.response.body)['text']
            else
              err_msg = "#{e}"
            end

            log.error(
              'failed to destroy block',
              n_batch: n_batch,
              block_id: block_id,
              error: err_msg
            )

            n_errors += 1
          end
        end

        n_batch += 1
      end

      log.info('done', n_killed: n_killed, n_errors: n_errors)
      0
    end

    private

    attr_reader :batch_size, :travis_client, :bluebox_client

    def log
      ::Bluebox.logger
    end
  end
end
