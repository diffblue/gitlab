# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230325200700_backfill_hashed_root_namespace_id_to_commits.rb')

RSpec.describe BackfillHashedRootNamespaceIdToCommits, feature_category: :global_search do
  let(:version) { 20230325200700 }
  let(:version_mapping_migration) { 20230320011400 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:index_name) { ::Elastic::Latest::CommitConfig.index_name }
  let(:migration) { described_class.new(version) }

  let_it_be_with_reload(:projects) { create_list(:project, 3, :repository) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.throttle_delay).to eq(5.seconds)
      expect(migration.batch_size).to eq(10_000)
      expect(migration).to be_retry_on_failure
    end
  end

  describe '.migrate', :elastic_clean, :sidekiq_inline do
    let(:client) { ::Gitlab::Search::Client.new }

    before do
      allow(migration).to receive(:client).and_return(client)
    end

    context 'when no data needs to be updated' do
      it 'does not execute update_by_query', :aggregate_failures do
        set_elasticsearch_migration_to(version_mapping_migration, including: true)

        projects.each { |p| p.repository.index_commits_and_blobs }

        ensure_elasticsearch_index!

        expect(client).not_to receive(:update_by_query)
        expect(migration).to be_completed

        migration.migrate

        expect(migration).to be_completed
      end

      context 'when project is not found' do
        before do
          allow(migration).to receive(:completed?).and_return(false)
          allow(migration).to receive(:search_projects).and_return([non_existing_record_id.to_s])
        end

        it 'schedules ElasticDeleteProjectWorker' do
          expect(ElasticDeleteProjectWorker).to receive(:perform_async)
            .with(non_existing_record_id, "project_#{non_existing_record_id}")

          migration.migrate
        end
      end
    end

    context 'when task is in progress' do
      before do
        allow(migration).to receive(:batch_size).and_return(1)
        stub_const("#{described_class}::MAX_PROJECTS_TO_PROCESS", 1)

        set_elasticsearch_migration_to(version_mapping_migration, including: false)

        projects.each { |p| p.repository.index_commits_and_blobs }
        ensure_elasticsearch_index!

        # prep in progress project
        migration.migrate

        # stub in progress task
        allow(helper).to receive(:task_status).and_call_original
        task_id = migration.migration_state[:projects_in_progress].first[:task_id]
        allow(helper).to receive(:task_status).with(task_id: task_id).and_return('completed' => false)
      end

      context 'when max projects are in progress' do
        it 'does not kick off a new task and writes the same data back to the migration_state', :aggregate_failures do
          expected_task_id = migration.migration_state[:projects_in_progress].first[:task_id]

          expect(client).not_to receive(:update_by_query)
          expect(migration).to receive(:set_migration_state).once

          migration.migrate

          expect(migration.migration_state[:projects_in_progress].first[:task_id]).to eq(expected_task_id)
        end
      end

      context 'when more projects can be run' do
        it 'kicks off a new task and adds a new project to the migration_state', :aggregate_failures do
          stub_const("#{described_class}::MAX_PROJECTS_TO_PROCESS", 2)

          migration_state = migration.migration_state
          expected_task_id = migration_state[:projects_in_progress].first[:task_id]

          expect(client).to receive(:update_by_query).once.and_call_original

          migration.migrate

          actual_task_ids = migration.migration_state[:projects_in_progress].pluck(:task_id)
          expect(actual_task_ids).to include(expected_task_id)
          expect(migration.migration_state[:projects_in_progress].size).to eq(2)
        end
      end

      shared_examples_for 'starts a new task' do
        it 'calls updated_by_query and updates migration_state with new task_id', :aggregate_failures do
          # no guarantee that the same project will be picked due to Elasticsearch results not being sorted
          expected_task_id = migration.migration_state[:projects_in_progress].first[:task_id]
          expect(client).to receive(:update_by_query).and_call_original

          migration.migrate

          expect(migration.migration_state[:projects_in_progress].first[:task_id]).not_to eq(expected_task_id)
          expect(migration.migration_state[:projects_in_progress].size).to eq(1)
        end
      end

      context 'when the task is completed' do
        before do
          task_id = migration.migration_state[:projects_in_progress].first[:task_id]
          allow(helper).to receive(:task_status).with(task_id: task_id).and_return('completed' => true)
        end

        it_behaves_like 'starts a new task'
      end

      context 'when the task returns an error' do
        before do
          task_id = migration.migration_state[:projects_in_progress].first[:task_id]
          allow(helper).to receive(:task_status).with(task_id: task_id)
                                                .and_return({ 'error' =>
                                                                { 'reason' => 'malformed task id PjA168i7Qg6z-JUD_XC12',
                                                                  'type' => 'illegal_argument_exception' } })
        end

        it_behaves_like 'starts a new task'
      end

      context 'when task is not found' do
        before do
          projects_in_progress = migration.migration_state[:projects_in_progress]
          projects_in_progress.first[:task_id] = 'oTUltX4IQMOUUVeiohTt8A:124'
          migration.set_migration_state(projects_in_progress: projects_in_progress)
        end

        it_behaves_like 'starts a new task'

        it 'does not raise an error' do
          expect { migration.migrate }.not_to raise_error
        end
      end
    end

    context 'when update_by_query returns failures' do
      before do
        allow(migration).to receive(:batch_size).and_return(1)
        stub_const("#{described_class}::MAX_PROJECTS_TO_PROCESS", 1)

        set_elasticsearch_migration_to(version_mapping_migration, including: false)

        projects.each { |p| p.repository.index_commits_and_blobs }
        ensure_elasticsearch_index!
      end

      it 'does not write a new task into the migration_state', :aggregate_failures do
        # two projects are attempted because the search queries MAX_PROJECTS_TO_PROCESS * 2
        expect(client).to receive(:update_by_query).twice.and_return({ 'failures' => ['failed'] })
        expect(migration).to receive(:set_migration_state).twice.and_call_original

        expect { migration.migrate }.not_to raise_error

        expect(migration.migration_state[:projects_in_progress]).to be_empty
      end
    end
  end

  describe '.completed?', :elastic, :sidekiq_inline do
    subject(:completed) { migration.completed? }

    context 'when commits are missing hashed_root_namespace_id' do
      before do
        set_elasticsearch_migration_to(version_mapping_migration, including: false)

        projects.each { |p| p.repository.index_commits_and_blobs }

        ensure_elasticsearch_index!
      end

      it { is_expected.to eq false }
    end

    context 'when no commits are missing hashed_root_namespace_id' do
      before do
        set_elasticsearch_migration_to(version_mapping_migration, including: true)

        projects.each { |p| p.repository.index_commits_and_blobs }

        ensure_elasticsearch_index!
      end

      it { is_expected.to eq true }
    end
  end

  describe 'integration test', :elastic_clean, :sidekiq_inline do
    before do
      set_elasticsearch_migration_to(version_mapping_migration, including: false)

      projects.each { |p| p.repository.index_commits_and_blobs }

      ensure_elasticsearch_index!
    end

    it 'updates documents in batches', :aggregate_failures do
      # calculate how many commits are in each project in the index
      query = { bool: { must: [{ term: { rid: projects.first.id } }] } }
      commit_count = helper.client.count(index: migration.index_name, body: { query: query })['count']

      allow(migration).to receive(:batch_size).and_return((commit_count / 2.to_f).ceil)
      stub_const("#{described_class}::MAX_PROJECTS_TO_PROCESS", 2)

      expect(migration).not_to be_completed
      expect(migration).to receive(:update_by_query).exactly(6).times.and_call_original

      # rid is stored as keyword type in the index
      expected_migration_project_ids = projects.pluck(:id).map(&:to_s)

      migrate_batch_of_projects(migration)

      counter = 0
      while counter < 10 && migration.migration_state[:projects_in_progress].present?
        actual_project_ids = migration.migration_state[:projects_in_progress].pluck(:project_id)
        expect(expected_migration_project_ids).to include(*actual_project_ids)

        migrate_batch_of_projects(migration)
        counter += 1
      end

      expect(migration).to be_completed
    end

    def migrate_batch_of_projects(migration)
      old_migration_state = migration.migration_state[:projects_in_progress]
      10.times do |_| # Max 0.1s waiting
        migration.migrate
        break if old_migration_state != migration.migration_state[:projects_in_progress]

        sleep 0.01
      end
    end
  end
end
