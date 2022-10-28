# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateSidekiqJobs, :clean_gitlab_redis_queues do
  around do |example|
    Sidekiq::Testing.disable!(&example)
  end

  describe '#up', :aggregate_failures, :silence_stdout do
    before do
      EmailReceiverWorker.sidekiq_options queue: 'email_receiver'
      EmailReceiverWorker.perform_async('foo')
      EmailReceiverWorker.perform_async('bar')
    end

    it 'migrates the jobs to the correct destination queue' do
      allow(Gitlab::SidekiqConfig).to receive(:worker_queue_mappings).and_return({ "EmailReceiverWorker" => "default" })
      expect(queue_length('email_receiver')).to eq(2)
      expect(queue_length('default')).to eq(0)
      migrate!
      expect(queue_length('email_receiver')).to eq(0)
      expect(queue_length('default')).to eq(2)

      jobs = list_jobs('default')
      expect(jobs[0]).to include("class" => "EmailReceiverWorker", "args" => ["bar"])
      expect(jobs[1]).to include("class" => "EmailReceiverWorker", "args" => ["foo"])
    end

    context 'with illegal JSON payload' do
      let(:job) { '{foo: 1}' }

      before do
        Sidekiq.redis do |conn|
          conn.lpush("queue:email_receiver", job)
        end
      end

      it 'logs an error' do
        allow(::Gitlab::BackgroundMigration::Logger).to receive(:build).and_return(Logger.new($stdout))
        migrate!
        expect($stdout.string).to include("Unmarshal JSON payload from SidekiqMigrateJobs failed. Job: #{job}")
      end
    end

    def queue_length(queue_name)
      Sidekiq.redis do |conn|
        conn.llen("queue:#{queue_name}")
      end
    end

    def list_jobs(queue_name)
      Sidekiq.redis { |conn| conn.lrange("queue:#{queue_name}", 0, -1) }
        .map { |item| Sidekiq.load_json item }
    end
  end
end
