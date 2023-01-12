# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20220713103500_delete_commits_from_original_index.rb')

RSpec.describe DeleteCommitsFromOriginalIndex, :elastic_clean, feature_category: :global_search do
  let(:version) { 20220713103500 }
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

  context 'commits are already deleted' do
    it 'does not execute delete_by_query' do
      expect(migration.completed?).to be_truthy
      expect(helper.client).not_to receive(:delete_by_query)

      migration.migrate
    end
  end

  context 'commits are still present in the index', :sidekiq_inline do
    let(:project) { create(:project, :repository) }

    before do
      set_elasticsearch_migration_to :migrate_commits_to_separate_index, including: false

      project.repository.index_commits_and_blobs # ensure objects are indexed
      ensure_elasticsearch_index!
    end

    it 'removes commits from the index' do
      expect(migration.completed?).to be_falsey

      migration.migrate
      expect(migration.migration_state).to match(task_id: anything)

      # the migration might not complete after the initial task is created
      # so make sure it actually completes
      50.times do |_| # Max 0.5s waiting
        migration.migrate
        break if migration.completed?

        sleep 0.01
      end

      expect(migration.migration_state).to match(task_id: nil)
      expect(migration.completed?).to be_truthy
    end

    context 'task in progress' do
      let(:client) { instance_double('Elasticsearch::Transport::Client') }

      before do
        allow(migration).to receive(:completed?).and_return(false)
        allow(migration).to receive(:client).and_return(client)
        allow(helper).to receive(:task_status).and_return('completed' => false)
        migration.set_migration_state(task_id: 'task_1')
      end

      it 'does nothing if task is not completed' do
        migration.migrate

        expect(client).not_to receive(:delete_by_query)
      end
    end
  end

  context 'migration fails' do
    let(:client) { instance_double('Elasticsearch::Transport::Client') }

    before do
      allow(migration).to receive(:client).and_return(client)
      allow(migration).to receive(:completed?).and_return(false)
    end

    context 'exception is raised' do
      before do
        allow(client).to receive(:delete_by_query).and_raise(StandardError)
      end

      it 'resets task_id' do
        migration.set_migration_state(task_id: 'task_1')

        expect { migration.migrate }.to raise_error(StandardError)
        expect(migration.migration_state).to match(task_id: nil)
      end
    end

    context 'es responds with errors' do
      before do
        allow(client).to receive(:delete_by_query).and_return('task' => 'task_1')
        allow(migration).to receive(:get_number_of_shards).and_return(1)
      end

      context 'when a task throws an error' do
        before do
          allow(helper).to receive(:task_status).and_return('failures' => ['failed'])
          migration.migrate
        end

        it 'resets task_id' do
          expect { migration.migrate }.to raise_error(/Failed to delete commits/)
          expect(migration.migration_state).to match(task_id: nil)
        end
      end

      context 'when delete_by_query throws an error' do
        before do
          allow(client).to receive(:delete_by_query).and_return('failures' => ['failed'])
        end

        it 'resets task_id' do
          expect { migration.migrate }.to raise_error(/Failed to delete commits/)
          expect(migration.migration_state).to match(task_id: nil)
        end
      end
    end
  end
end
