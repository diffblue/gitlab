# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210510113500_delete_merge_requests_from_original_index.rb')

RSpec.describe DeleteMergeRequestsFromOriginalIndex, :elastic, :sidekiq_inline do
  let(:version) { 20210510113500 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.throttle_delay).to eq(3.minutes)
    end
  end

  context 'merge requests are already deleted' do
    it 'does not execute delete_by_query' do
      expect(migration.completed?).to be_truthy
      expect(helper.client).not_to receive(:delete_by_query)

      migration.migrate
    end
  end

  context 'merge requests are still present in the index' do
    let!(:merge_requests) { create_list(:merge_request, 10, :unique_branches) }

    before do
      set_elasticsearch_migration_to :migrate_merge_requests_to_separate_index, including: false
      ensure_elasticsearch_index!
    end

    it 'removes merge requests from the index' do
      # initiate the task in Elasticsearch
      migration.migrate
      expect(migration.migration_state).to match(retry_attempt: 0, task_id: anything)
      task_id = migration.migration_state[:task_id]

      # the migration might not complete after the initial task is created
      # so make sure it actually completes
      50.times do |_| # Max 0.5s waiting
        migration.migrate
        break if migration.completed?

        sleep 0.01
      end

      # verify clean up of the task from Elasticsearch
      expect(migration.migration_state).to match(retry_attempt: 0, task_id: nil)
      expect { helper.client.get(index: '.tasks', type: 'task', id: task_id) }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end
  end

  context 'migration fails' do
    let(:client) { double('Elasticsearch::Transport::Client') }

    before do
      allow(migration).to receive(:client).and_return(client)
      allow(migration).to receive(:completed?).and_return(false)
    end

    context 'exception is raised' do
      before do
        allow(client).to receive(:delete_by_query).and_raise(StandardError)
      end

      it 'increases retry_attempt' do
        migration.set_migration_state(retry_attempt: 1)

        expect { migration.migrate }.to raise_error(StandardError)
        expect(migration.migration_state).to match(retry_attempt: 2, task_id: nil)
      end

      it 'fails the migration after too many attempts' do
        stub_const('DeleteMergeRequestsFromOriginalIndex::MAX_ATTEMPTS', 2)

        # run migration up to the set MAX_ATTEMPTS set in the migration
        DeleteMergeRequestsFromOriginalIndex::MAX_ATTEMPTS.times do
          expect { migration.migrate }.to raise_error(StandardError)
        end

        migration.migrate

        expect(migration.migration_state).to match(retry_attempt: 2, task_id: nil, halted: true, failed: true, halted_indexing_unpaused: false)
      end
    end

    context 'es responds with errors' do
      before do
        allow(client).to receive(:delete_by_query).and_return('task' => 'task_1')
      end

      context 'when a task throws an error' do
        before do
          allow(helper).to receive(:task_status).and_return('failures' => ['failed'])
          migration.migrate
        end

        it 'raises an error and increases retry attempt' do
          expect { migration.migrate }.to raise_error(/Failed to delete merge requests/)
          expect(migration.migration_state).to match(retry_attempt: 1, task_id: nil)
        end
      end

      context 'when delete_by_query throws an error' do
        before do
          allow(client).to receive(:delete_by_query).and_return('failures' => ['failed'])
        end

        it 'raises an error and increases retry attempt' do
          expect { migration.migrate }.to raise_error(/Failed to delete merge requests/)
          expect(migration.migration_state).to match(retry_attempt: 1, task_id: nil)
        end
      end
    end
  end
end
