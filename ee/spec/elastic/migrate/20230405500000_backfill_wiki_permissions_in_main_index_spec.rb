# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230405500000_backfill_wiki_permissions_in_main_index.rb')

RSpec.describe BackfillWikiPermissionsInMainIndex, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230405500000 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:migration) { described_class.new(version) }

  let_it_be_with_reload(:projects) { create_list(:project, 3, :wiki_repo, visibility_level: 0, wiki_access_level: 0) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)

    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration).to be_retry_on_failure
      expect(migration.throttle_delay).to eq(5.seconds)
      expect(migration.batch_size).to eq(10_000)
    end
  end

  describe 'when Elasticsearch gives 404' do
    context 'when Elasticsearch responds with NotFoundException' do
      let(:client) { instance_double('Elasticsearch::Transport::Client') }
      let(:update_by_query_response) { { 'failures' => ['failed'] } }

      before do
        allow(client).to receive(:update_by_query).and_return(update_by_query_response)

        allow(migration).to receive(:projects_having_wikis_with_missing_permissions).and_return(projects.map(&:id))
        allow(migration).to receive(:completed?).and_return(false)
        allow(migration).to receive(:client).and_return(client)
      end

      context 'when a task_status throws a NotFound Exception' do
        it 'removes entry from projects_in_progress in migration_state' do
          migration_state = projects.map { |p| { task_id: 'oTUltX4IQMOUUVeiohTt8A:124', project_id: p.id } }
          migration.set_migration_state(projects_in_progress: migration_state)
          expect(migration).to receive(:set_migration_state).with(projects_in_progress: []).twice

          expect { migration.migrate }.not_to raise_error

          expect(migration.migration_state[:projects_in_progress]).to match_array(migration_state)
        end
      end
    end
  end

  describe '.migrate' do
    before do
      projects.each do |p|
        p.wiki.create_page('index_page', 'Bla bla term1')
        p.wiki.index_wiki_blobs
      end
    end

    context 'with wiki permissions already existing in all wikis' do
      before do
        projects.each { |p| set_visibility_level_for_wikis(p) }
      end

      it 'does not execute update_by_query' do
        expect(migration).to be_completed
        expect(helper.client).not_to receive(:update_by_query)
        migration.migrate
      end
    end

    context 'with wiki permissions not present in wikis' do
      before do
        projects.each { |p| remove_visibility_level_for_wikis(p) }
      end

      context 'when task in progress' do
        let(:client) { instance_double('Elasticsearch::Transport::Client') }

        before do
          allow(migration).to receive(:completed?).and_return(false)
          allow(migration).to receive(:client).and_return(client)
          allow(migration).to receive(:projects_having_wikis_with_missing_permissions).and_return([])
          allow(helper).to receive(:task_status).with(task_id: 'task_1').and_return('completed' => false)
          migration.set_migration_state(projects_in_progress: [{ task_id: 'task_1', project_id: 1 }])
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
          allow(migration).to receive(:projects_having_wikis_with_missing_permissions).and_return([0])
          allow(migration).to receive(:completed?).and_return(false)
        end

        it 'logs failure when project is not found and schedules ElasticDeleteProjectWorker' do
          expect(migration).to receive(:log).with(/Enqueuing projects having wiki_blobs with missing permissions/).once
          expect(migration).to receive(:log).with(/Project not found/).once
          expect(migration).to receive(:log).with(/Setting migration_state to/).once
          expect(ElasticDeleteProjectWorker).to receive(:perform_async).with(0, 'project_0')
          migration.migrate
        end
      end

      context 'when migration fails' do
        let(:client) { instance_double('Elasticsearch::Transport::Client') }

        before do
          allow(client).to receive(:update_by_query).and_return(update_by_query_response)
          allow(helper).to receive(:task_status).with(task_id: 'task_1').and_return(task_status_response)

          allow(migration).to receive(:projects_having_wikis_with_missing_permissions).and_return(projects.map(&:id))
          allow(migration).to receive(:completed?).and_return(false)
          allow(migration).to receive(:client).and_return(client)
        end

        context 'when Elasticsearch responds with errors' do
          context 'when a task throws an error' do
            let(:task_status_response) { { 'failures' => ['failed'] } }
            let(:update_by_query_response) { { 'task' => 'task_1' } }

            it 'removes entry from projects_in_progress in migration_state' do
              migration_state = projects.map { |p| { task_id: 'task_1', project_id: p.id } }
              migration.set_migration_state(projects_in_progress: migration_state)
              expect(migration).to receive(:set_migration_state).with(projects_in_progress: [])
              expect(migration).to receive(:set_migration_state).with(projects_in_progress: migration_state)

              expect { migration.migrate }.not_to raise_error

              expect(migration.migration_state[:projects_in_progress]).to match_array(migration_state)
            end
          end

          context 'when update_by_query throws an error' do
            let(:task_status_response) { {} }
            let(:update_by_query_response) { { 'failures' => ['failed'] } }

            it 'removes entry from projects_in_progress in migration_state' do
              migration.set_migration_state({}) # simulate first run

              expect { migration.migrate }.not_to raise_error
              expect(migration.migration_state).to match(projects_in_progress: [])
            end
          end
        end
      end
    end
  end

  describe 'integration test' do
    let(:old_version_without_wiki_permissions) { 20230321202400 }

    before do
      set_elasticsearch_migration_to(old_version_without_wiki_permissions, including: false)

      projects.each do |project|
        project.wiki.create_page('index_page', 'Bla bla term1')
        project.wiki.create_page('home_page', 'Bla bla term2')
        project.wiki.create_page('index_page2', 'Bla bla term3')
        project.wiki.create_page('home_page2', 'Bla bla term4')
        project.wiki.index_wiki_blobs
      end
      ensure_elasticsearch_index!
      projects.each { |project| remove_visibility_level_for_wikis(project) }
      set_elasticsearch_migration_to(version, including: false)
    end

    it 'updates documents in batches' do
      # calculate how many files are in each project in the index
      query = { bool: { must: [{ term: { project_id: projects.first.id } }, { term: { type: 'wiki_blob' } }] } }
      file_count = helper.client.count(index: helper.target_name, body: { query: query })['count']
      allow(migration).to receive(:batch_size).and_return(file_count / 2)
      stub_const("BackfillWikiPermissionsInMainIndex::MAX_PROJECTS_TO_PROCESS", 2)

      expect(migration).not_to be_completed
      expect(migration).to receive(:update_by_query).exactly(projects.size * 2).times.and_call_original

      # process first two projects and half of the records
      # the projects are returned ordered by record count, then by project_id
      # make sure to give time to process the tasks
      old_migration_state = migration.migration_state[:projects_in_progress]

      5.times do |_|
        migration.migrate
        break if old_migration_state != migration.migration_state[:projects_in_progress]
      end

      expected_migration_project_ids = projects.map(&:id)

      project_ids = migration.migration_state[:projects_in_progress].pluck(:project_id)
      expect(expected_migration_project_ids).to include(*project_ids)
      expect(project_ids.size).to eq(2)

      # process two projects, the last project is now returned because it has the most documents to update
      old_migration_state = migration.migration_state[:projects_in_progress]
      5.times do |_|
        migration.migrate
        break if old_migration_state != migration.migration_state[:projects_in_progress]
      end

      project_ids = migration.migration_state[:projects_in_progress].pluck(:project_id)
      expect(expected_migration_project_ids).to include(*project_ids)
      expect(project_ids.size).to eq(2)

      # process two projects, the second project is returned because the first project is completed
      old_migration_state = migration.migration_state[:projects_in_progress]
      5.times do |_|
        migration.migrate
        break if old_migration_state != migration.migration_state[:projects_in_progress]
      end

      project_ids = migration.migration_state[:projects_in_progress].pluck(:project_id)
      expect(expected_migration_project_ids).to include(*project_ids)
      expect(project_ids.size).to eq(2)

      # all projects are marked as completed
      old_migration_state = migration.migration_state[:projects_in_progress]
      5.times do |_|
        migration.migrate
        break if old_migration_state != migration.migration_state[:projects_in_progress]
      end

      expect(migration.migration_state[:projects_in_progress]).to be_empty
      expect(migration).to be_completed
    end
  end

  def set_visibility_level_for_wikis(project)
    source = "ctx._source.wiki_access_level = #{project.wiki_access_level};" \
             "ctx._source.visibility_level = #{project.visibility_level};"
    update_by_query project, source
  end

  def remove_visibility_level_for_wikis(project)
    source = "ctx._source.remove('visibility_level');ctx._source.remove('wiki_access_level')"
    update_by_query project, source
  end

  def update_by_query(project, source)
    Project.__elasticsearch__.client.update_by_query({
      index: Project.__elasticsearch__.index_name,
      refresh: true,
      body: {
        script: {
          source: source,
          lang: 'painless'
        },
        query: {
          bool: {
            filter: [
              {
                term: {
                  type: 'wiki_blob'
                }
              },
              {
                has_parent: {
                  parent_type: 'project',
                  query: {
                    term: {
                      id: project.id
                    }
                  }
                }
              }
            ]
          }
        }
      }
    })
  end
end
