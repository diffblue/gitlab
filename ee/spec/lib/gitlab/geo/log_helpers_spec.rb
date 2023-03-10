# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogHelpers, feature_category: :geo_replication do
  before do
    stub_const('FakeLogHelpersConsumer', Class.new)

    FakeLogHelpersConsumer.class_eval do
      include Gitlab::Geo::LogHelpers # rubocop:disable RSpec/DescribedClass

      def execute
        log_error('Test message')
      end
    end
  end

  def stub_sidekiq_job_context(context)
    original_value = Thread.current[:sidekiq_context]
    Thread.current[:sidekiq_context] = context

    yield

    Thread.current[:sidekiq_context] = original_value
  end

  context 'Sidekiq context' do
    it 'does not log empty job_id when running outside of job' do
      expect(Gitlab::Geo::Logger).to receive(:error).with({ class: 'FakeLogHelpersConsumer',
                                                            gitlab_host: 'localhost',
                                                            message: 'Test message' })

      FakeLogHelpersConsumer.new.execute
    end

    it 'logs sidekiq_context' do
      expect(Gitlab::Geo::Logger).to receive(:error).with({ class: 'FakeLogHelpersConsumer',
                                                            gitlab_host: 'localhost',
                                                            message: 'Test message',
                                                            job_id: '5b9b108c7558fe3c32cc61a5' })

      stub_sidekiq_job_context(['TestWorker JID-5b9b108c7558fe3c32cc61a5']) do
        FakeLogHelpersConsumer.new.execute
      end
    end
  end
end
