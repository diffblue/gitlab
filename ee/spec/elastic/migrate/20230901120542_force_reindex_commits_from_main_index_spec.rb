# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230901120542_force_reindex_commits_from_main_index.rb')

RSpec.describe ForceReindexCommitsFromMainIndex, :elastic_delete_by_query, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230901120542 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:client) { ::Gitlab::Search::Client.new }
  let_it_be_with_reload(:projects) { create_list(:project, 3, :repository) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
    allow(migration).to receive(:client).and_return(client)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.batch_size).to eq 200
      expect(migration.throttle_delay).to eq(3.minutes)
      expect(migration).to be_retry_on_failure
    end
  end

  describe '.completed?' do
    before do
      Project.all.each { |p| populate_commits_in_main_index!(p) }
    end

    context 'when no commits documents are in the main index' do
      before do
        client.delete_by_query(index: helper.target_name, conflicts: 'proceed', refresh: true,
          body: { query: { bool: { filter: { term: { type: 'commit' } } } } }
        )
      end

      it 'returns true' do
        expect(migration).to be_completed
      end
    end

    context 'when commits documents exists in the main index' do
      context 'and schema_version is set for all documents' do
        before do
          Project.all.each { |p| set_schema_version(p) }
        end

        it 'returns true' do
          expect(migration).to be_completed
        end
      end

      context 'and schema_version is not set for some documents' do
        before do
          set_schema_version(Project.first)
        end

        it 'returns false' do
          expect(migration).not_to be_completed
        end
      end
    end
  end

  describe '.migrate' do
    let(:batch_size) { 1 }

    before do
      allow(migration).to receive(:batch_size).and_return(batch_size)
      Project.all.each { |p| populate_commits_in_main_index!(p) }
    end

    context 'if migration is completed' do
      before do
        Project.all.each { |p| set_schema_version(p) }
      end

      it 'performs logging and does not call ElasticCommitIndexerWorker' do
        expect(migration).to receive(:log).with("Setting migration_state to #{{ documents_remaining: 0 }.to_json}").once
        expect(migration).to receive(:log).with('Checking if migration is finished', { total_remaining: 0 }).once
        expect(migration).to receive(:log).with('Migration Completed', { total_remaining: 0 }).once
        expect(ElasticCommitIndexerWorker).not_to receive(:perform_in)
        migration.migrate
      end
    end

    context 'if migration is not completed' do
      it 'calls ElasticCommitIndexerWorker and performs force indexing' do
        delay = a_value_between(0, migration.throttle_delay.seconds.to_i)
        initial_documents_left_to_be_indexed_count = documents_left_to_be_indexed_count
        expect(initial_documents_left_to_be_indexed_count).to be > 0 # Ensure that the migration is not already finished
        expect(ElasticCommitIndexerWorker).to receive(:perform_in).with(delay, anything, false, force: true)
        expect(migration).not_to be_completed
        migration.migrate
        expect(initial_documents_left_to_be_indexed_count - documents_left_to_be_indexed_count).to eq batch_size
        expect(migration).not_to be_completed
        expect(ElasticCommitIndexerWorker).to receive(:perform_in).with(delay, anything, false, force: true).twice
        10.times do
          break if migration.completed?

          migration.migrate
        end
        expect(indexed_documents_count).to eq Project.count
        expect(migration).to be_completed
      end
    end
  end

  def populate_commits_in_main_index!(project)
    client.index(index: helper.target_name, routing: "project_#{project.id}", refresh: true,
      body: { commit: { type: 'commit',
                        author: { name: 'F L', email: 't@t.com', time: Time.now.strftime('%Y%m%dT%H%M%S+0000') },
                        committer: { name: 'F L', email: 't@t.com', time: Time.now.strftime('%Y%m%dT%H%M%S+0000') },
                        rid: project.id, message: 'test' },
              join_field: { name: 'commit', parent: "project_#{project.id}" },
              repository_access_level: project.repository_access_level, type: 'commit',
              visibility_level: project.visibility_level })
  end

  def set_schema_version(project)
    query = { bool: { filter: [{ term: { type: 'commit' } }, { term: { 'commit.rid' => project.id.to_s } }],
                      must_not: { exists: { field: 'schema_version' } } } }
    script = { source: "ctx._source.schema_version = #{described_class::SCHEMA_VERSION}" }
    client.update_by_query(index: helper.target_name, routing: "project_#{project.id}", conflicts: 'proceed',
      body: { query: query, script: script }, refresh: true
    )
  end

  def indexed_documents_count
    query = { bool: { filter: [{ term: { type: 'commit' } },
      { term: { schema_version: described_class::SCHEMA_VERSION } }] } }
    get_documents_count(query)
  end

  def documents_left_to_be_indexed_count
    query = { bool: { filter: { term: { type: 'commit' } }, must_not: { exists: { field: 'schema_version' } } } }
    get_documents_count(query)
  end

  def get_documents_count(query)
    refresh_index!
    client.count(index: helper.target_name, body: { query: query })['count']
  end
end
