# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221221110300_backfill_traversal_ids_to_blobs_and_wiki_blobs.rb')

RSpec.describe BackfillTraversalIdsToBlobsAndWikiBlobs, :elastic_clean, :sidekiq_inline,
feature_category: :global_search do
  let(:version) { 20221221110300 }
  let(:old_version_without_traversal_ids) { 20221213090600 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:index_name) { Project.__elasticsearch__.index_name }
  let(:migration) { described_class.new(version) }

  let_it_be_with_reload(:projects) { create_list(:project, 3, :repository) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)

    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.retry_on_failure?).to be_truthy
      expect(migration.throttle_delay).to eq(45.seconds)
      expect(migration.batch_size).to eq(100_000)
    end
  end

  describe '.migrate' do
    context 'with traversal_ids in all projects' do
      it 'does not execute update_by_query' do
        projects = create_list(:project, 2, :repository)
        projects.each { |p| p.repository.index_commits_and_blobs }

        ensure_elasticsearch_index!

        migration.migrate

        expect(migration.completed?).to be_truthy
        expect(helper.client).not_to receive(:update_by_query)
      end
    end

    context 'when task in progress' do
      let(:client) { instance_double('Elasticsearch::Transport::Client') }

      before do
        allow(migration).to receive(:completed?).and_return(false)
        allow(migration).to receive(:client).and_return(client)
        allow(helper).to receive(:task_status).and_return('completed' => false)
        migration.set_migration_state(task_id: 'task_1')
      end

      it 'does nothing if task is not completed' do
        expect(client).not_to receive(:update_by_query)
        migration.migrate
      end
    end

    context 'with project not found exception' do
      let(:client) { instance_double('Elasticsearch::Transport::Client') }

      before do
        allow(migration).to receive(:client).and_return(client)
        allow(migration).to receive(:projects_with_missing_traversal_ids).and_return([0])
        allow(migration).to receive(:completed?).and_return(false)
      end

      it 'log failure when project is not found' do
        migration.migrate
        expect(migration).to receive(:log).with(/Searching for the projects with missing traversal_ids/).once
        expect(migration).to receive(:log).with(/projects with missing traversal_ids/).once
        expect(migration).to receive(:log).with(/Project not found/).once
        migration.migrate
      end
    end

    context 'when migration fails' do
      let(:client) { instance_double('Elasticsearch::Transport::Client') }

      before do
        allow(client).to receive(:update_by_query).and_return(update_by_query_response)
        allow(helper).to receive(:task_status).with(task_id: 'task_1').and_return(task_status_response)

        allow(migration).to receive(:projects_with_missing_traversal_ids).and_return(projects.map(&:id))
        allow(migration).to receive(:completed?).and_return(false)
        allow(migration).to receive(:client).and_return(client)
      end

      context 'when Elasticsearch responds with errors' do
        context 'when a task throws an error' do
          let(:task_status_response) { { 'failures' => ['failed'] } }
          let(:update_by_query_response) { { 'task' => 'task_1' } }

          it 'resets task_id' do
            migration.set_migration_state(task_id: 'task_1') # simulate a task in progress

            expect { migration.migrate }.to raise_error(/Failed to update projects/)
            expect(migration.migration_state).to match(task_id: nil)
          end
        end

        context 'when update_by_query throws an error' do
          let(:task_status_response) { {} }
          let(:update_by_query_response) { { 'failures' => ['failed'] } }

          it 'sets task_id to nil' do
            migration.set_migration_state(task_id: nil) # simulate a new task being created

            expect { migration.migrate }.to raise_error(/Failed to update project with project_id/)
            expect(migration.migration_state).to match(task_id: nil)
          end
        end
      end
    end
  end

  describe 'integration test' do
    before do
      set_elasticsearch_migration_to(old_version_without_traversal_ids, including: false)

      projects.each do |project|
        project.repository.index_commits_and_blobs # ensure objects are indexed
      end

      ensure_elasticsearch_index!

      set_elasticsearch_migration_to(version, including: false)
    end

    it 'updates all documents in single batch' do
      expect(migration.completed?).to be_falsey

      migration.migrate

      expect(migration.migration_state).to match(task_id: anything)

      # the migration might not complete after the initial task is created
      # so make sure it actually completes
      100.times do |_| # Max 1s waiting
        migration.migrate
        break if migration.migration_state[:task_id].nil?

        sleep 0.01
      end

      expect(migration.completed?).to be_truthy
    end

    context 'with more than one batch' do
      before do
        allow(migration).to receive(:batch_size).and_return(2)
      end

      it 'tracks all blobs and wiki_blobs in two iterations in one batch' do
        # First batch
        # the migration might not complete after the initial task is created
        # so make sure it actually completes
        50.times do |_| # Max 0.5s waiting
          migration.migrate
          break if migration.migration_state[:task_id].nil?

          sleep 0.01
        end

        expect(migration.completed?).to be_falsey

        # Second batch
        # the migration might not complete after the initial task is created
        # so make sure it actually completes
        100.times do |_| # Max 1s waiting
          migration.migrate
          break if migration.completed?

          sleep 0.01
        end

        migration.migrate

        expect(migration.completed?).to be_truthy
        expect(migration.migration_state).to match(task_id: nil)
      end
    end
  end
end
