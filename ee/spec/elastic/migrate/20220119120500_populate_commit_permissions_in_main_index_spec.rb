# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20220119120500_populate_commit_permissions_in_main_index.rb')

RSpec.describe PopulateCommitPermissionsInMainIndex, feature_category: :global_search do
  let(:version) { 20220119120500 }
  let(:migration) { described_class.new(version) }
  let(:client) { Project.__elasticsearch__.client }
  let(:permissions_matrix) { described_class::PERMISSIONS_MATRIX }

  let(:projects) do
    permissions_matrix.map do |visibility_level, repository_access_level|
      create(:project,
             :repository,
             visibility_level: visibility_level,
             repository_access_level: repository_access_level)
    end
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.batch_size).to eq(100_000)
      expect(migration.throttle_delay).to eq(1.minute)
    end
  end

  describe 'permissions matrix' do
    let(:permutation_idx) { 1 }

    before do
      allow(migration).to receive(:migration_state).and_return(permutation_idx: permutation_idx)
    end

    context 'when permutation_idx is in the bounds of permissions matrix' do
      it 'uses the correct visibility levels' do
        expect(migration.visibility_level).to eq(permissions_matrix[permutation_idx][0])
        expect(migration.repository_access_level).to eq(permissions_matrix[permutation_idx][1])
      end
    end

    context 'permutation_idx is out of bounds of permissions matrix' do
      let(:permutation_idx) { 9000 }

      it 'has nil values' do
        expect(migration.visibility_level).to be_nil
        expect(migration.repository_access_level).to be_nil
      end

      it 'makes the migration a noop' do
        expect(migration).not_to receive(:update_by_query)
        expect(migration).not_to receive(:set_migration_state)
        migration.migrate
      end
    end
  end

  describe 'integration test', :elastic, :sidekiq_inline do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      set_elasticsearch_migration_to :populate_commit_permissions_in_main_index, including: false

      # ensure Projects are created and indexed
      projects.each { |p| p.repository.index_commits_and_blobs }

      ensure_elasticsearch_index!
    end

    context 'when visibility levels are missing' do
      it "updates commit documents with correct permissions based on permutation index" do
        expect { migration.migrate }.to change { migration.permutation_idx }.from(nil).to(0)

        # Commits generated in tests already have visibility levels, so we need to remove them
        expect(migration).to be_completed
        projects.each do |p|
          remove_visibility_level_for_commits(raw_commits_for_project(p))
        end

        # use a small batch size to verify batching processes documents properly
        described_class.batch_size(10)

        # adding multiple expectations here to avoid setup/teardown time of indices on each test.
        permissions_matrix.each.with_index do |(_visibility_level, _repository_access_level), permutation_idx|
          expect(migration.permutation_idx).to eq(permutation_idx)
          expect(migration).not_to be_completed

          # Since there are more commits than the batch size, migrating should not change the permutation_idx
          # This migration launches the update_by_query task
          expect { migration.migrate }.to not_change { migration.permutation_idx }

          wait_for_migration_task_to_complete(migration)

          # Since there are more commits than the batch size, migrating should not change the permutation_idx
          # This migration handles completion of update_by_query task
          expect { migration.migrate }.to not_change { migration.permutation_idx }

          # Calculate how many migrations need to be run to fully complete the permutation
          # We do not need to add one to the calculation to handle a final batch (remainder) which is less
          # than the batch_size because a full migration was run once above
          project = projects[permutation_idx]
          num_commits = raw_commits_for_project(project).length
          batches_to_complete_permutation = num_commits / migration.batch_size

          batches_to_complete_permutation.times do |batch|
            migration.migrate # handle launch of update_by_query task
            wait_for_migration_task_to_complete(migration) # wait for migration to complete

            # The migration will be permutation complete when the last batch is migrated
            # this needs to be checked before completion of the update_by_query task because the permutation_idx is
            # updated at that point
            expect(migration).to be_permutation_completed if batch == (batches_to_complete_permutation - 1)
            migration.migrate # handle completion of update_by_query task
          end

          if migration.completed?
            # The migration should be completed after the very last batch in the
            # very last permutation is run and complete.
            expect(migration.permutation_idx).to eq(permutation_idx)
          else
            expect(migration.permutation_idx).to eq(permutation_idx + 1)
          end
        end

        expect(migration).to be_completed
      end
    end

    context 'when visibility levels are not missing for a permutation' do
      it 'does not change visibility levels but increments permutation index' do
        expect(migration).to be_completed
        expect { migration.migrate }.to change { migration.permutation_idx }.from(nil).to(0) # setup

        # Remove visibility levels in commits for last project to ensure migration still
        # increments the permutation index
        remove_visibility_level_for_commits(raw_commits_for_project(projects.last))

        permissions_matrix.each.with_index do |(visibility_level, repository_access_level), permutation_idx|
          project = projects[permutation_idx]

          if project.id != projects.last.id
            expect(migration).to be_permutation_completed

            expect { migration.migrate }
              .to change { migration.permutation_idx }.from(permutation_idx).to(permutation_idx + 1)

            expect(raw_commits_for_project(project)).to all(
              include("visibility_level" => visibility_level,
                      "repository_access_level" => repository_access_level)
            )
          else
            expect(migration).not_to be_permutation_completed
          end
        end
      end
    end
  end

  describe 'migration state' do
    let(:task_id) { "task_id" }
    let(:permutation_idx) { 1 }
    let(:retry_attempt) { 2 }
    let(:documents_remaining) { 20 }
    let(:documents_remaining_for_permutation) { 4 }
    let(:permutation_completed) { false }
    let(:migrate) { migration.migrate }

    before do
      allow(migration).to receive(:migration_state).and_return(state)
      allow(migration).to receive(:update_by_query).and_return(task_id)
      allow(migration).to receive(:documents_remaining).and_return(documents_remaining)
      allow(migration).to receive(:documents_remaining_for_permutation).and_return(documents_remaining_for_permutation)
      allow(migration).to receive(:permutation_completed?).and_return(permutation_completed)
    end

    context 'when no state exists' do
      let(:state) { {} }

      it 'saves retry attempt and permutation index' do
        expect(migration).to receive(:set_migration_state).with(
          permutation_idx: 0,
          retry_attempt: 0,
          documents_remaining: documents_remaining
        )

        migrate
      end
    end

    context 'when a Elastic task does NOT exist in state' do
      let(:state) { { permutation_idx: permutation_idx } }

      it 'saves the elastic task_id to state' do
        expect(migration).to receive(:set_migration_state).with(
          permutation_idx: permutation_idx,
          task_id: task_id,
          documents_remaining: documents_remaining,
          documents_remaining_for_permutation: documents_remaining_for_permutation
        )
        migrate
      end
    end

    context 'when a Elastic task exists in state' do
      let(:state) { { permutation_idx: permutation_idx, task_id: task_id } }

      context 'and the task is completed' do
        it 'increments the permutation_idx and resets retry count, task_id and batch_num' do
          allow(migration).to receive(:task_completed?).and_return true
          allow(migration).to receive(:permutation_completed?).and_return true
          expect(migration).to receive(:set_migration_state).with(
            permutation_idx: permutation_idx + 1,
            batch_num: 0,
            task_id: nil,
            retry_attempt: 0,
            documents_remaining: documents_remaining,
            documents_remaining_for_permutation: documents_remaining_for_permutation
          )
          migrate
        end
      end

      context 'when task is still running' do
        it 'does not change the state' do
          allow(migration).to receive(:task_completed?).and_return false
          allow(migration).to receive(:permutation_completed?).and_return false
          expect(migration).not_to receive(:set_migration_state)
          migrate
        end
      end
    end

    context 'when an exception occurs' do
      let(:state) { { permutation_idx: permutation_idx, retry_attempt: retry_attempt } }

      it 'increments retry attempt and re-raises the exception' do
        allow(migration).to receive(:completed?).and_raise(KeyError) # arbitrary exception

        expect(migration).to receive(:set_migration_state).with(
          permutation_idx: permutation_idx,
          task_id: nil,
          retry_attempt: retry_attempt + 1,
          documents_remaining: documents_remaining,
          documents_remaining_for_permutation: documents_remaining_for_permutation
        )

        expect { migrate }.to raise_error(KeyError)
      end
    end

    context 'when max retries is reached' do
      let(:retry_attempt) { described_class::MAX_ATTEMPTS_PER_IDX }
      let(:state) { { permutation_idx: permutation_idx, retry_attempt: retry_attempt } }

      it 'fails the migration' do
        expect(migration).to receive(:fail_migration_halt_error!).with(retry_attempt: retry_attempt)
        migrate
      end
    end
  end

  describe '.completed?', :elastic, :sidekiq_inline do
    let(:project) { create(:project, :repository) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      set_elasticsearch_migration_to :populate_commit_permissions_in_main_index, including: false

      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    context 'when there are commits missing permissions' do
      before do
        remove_visibility_level_for_commits(raw_commits_for_project(project))
      end

      specify { expect(migration).not_to be_completed }

      context 'and the project is missing from the index' do
        before do
          client.delete(index: index_name, id: "project_#{project.id}", refresh: true) # remove parent project
        end

        specify { expect(migration).to be_completed }
      end
    end

    # no commit will be missing permissions due to how the migrations work for specs
    context 'when there are NO commits missing permissions' do
      specify { expect(migration).to be_completed }
    end
  end

  describe '.task_completed?' do
    let(:helper) { double(:helper) } # rubocop:disable RSpec/VerifiedDoubles
    let(:task_id) { 'example-task-id' }

    before do
      allow(migration).to receive(:helper).and_return(helper)
      expect(helper).to receive(:task_status).with(task_id: task_id).and_return(task_status)
    end

    context 'when elastic task is completed with no failures' do
      let(:task_status) do
        { 'completed' => true, 'response' => {} }
      end

      it 'is truthy' do
        expect(migration.task_completed?(task_id: task_id)).to be_truthy
      end
    end

    context 'when elastic task is completed with failures' do
      let(:task_status) do
        { 'completed' => true, 'response' => { 'failures' => 100 } }
      end

      it 'is truthy' do
        expect(migration).to receive(:log_raise).with("Update has failed with 100 failures")
        expect(migration.task_completed?(task_id: task_id)).to be_truthy
      end
    end

    context 'when elastic task is still running' do
      let(:task_status) do
        { 'completed' => false, 'response' => {} }
      end

      it 'is falsey' do
        expect(migration.task_completed?(task_id: task_id)).to be_falsey
      end
    end
  end

  describe '.permutation_completed?' do
    let(:filter) { double(:filter) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(migration).to receive(:visibility_level).and_return(123)
      allow(migration).to receive(:repository_access_level).and_return(456)
      expect(migration).to receive(:commits_missing_project_access_levels)
        .with(visibility_level: 123, repository_access_level: 456).and_return(filter)
      expect(migration).to receive(:count_of_commits_without_permissions).with(filter).and_return(doc_count)
    end

    context 'when there are commits matching current permutation missing permissions' do
      let(:doc_count) { 100 }

      specify { expect(migration).not_to be_permutation_completed }
    end

    context 'when there are no commits matching current permutation missing permissions' do
      let(:doc_count) { 0 }

      specify { expect(migration).to be_permutation_completed }
    end
  end

  private

  def index_name
    Repository.__elasticsearch__.index_name
  end

  def raw_commits_for_project(project)
    query = {
      term: { 'commit.rid' => project.id }
    }

    client.search(index: index_name, body: { size: 1000, query: query }).dig('hits', 'hits').map do |doc|
      doc.dig('_source')
    end
  end

  def remove_visibility_level_for_commits(commits)
    script = {
      source: "ctx._source.remove('visibility_level'); ctx._source.remove('repository_access_level');"
    }

    update_by_query(commits, script)
  end

  def update_by_query(commit_docs, script)
    client.update_by_query({
      index: index_name,
      wait_for_completion: true,
      refresh: true,
      body: {
        script: script,
        query: {
          bool: {
            must: [
              {
                terms: {
                  "commit.sha" => commit_docs.map { |c| c['commit']["sha"] }
                }
              },
              {
                term: {
                  "commit.rid" => {
                    value: commit_docs.first.dig('commit', 'rid') # project_id
                  }
                }
              }
            ]
          }
        }
      }
    })
  end

  def wait_for_migration_task_to_complete(migration)
    task_id = migration.task_id
    50.times.each do |attempt| # 5 second timeout duration
      migration.task_completed?(task_id: task_id) ? break : sleep(0.1)
    end
    es_helper.refresh_index(index_name: index_name)
  end
end
