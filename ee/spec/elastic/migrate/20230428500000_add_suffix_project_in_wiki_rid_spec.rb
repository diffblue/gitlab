# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230428500000_add_suffix_project_in_wiki_rid.rb')

RSpec.describe AddSuffixProjectInWikiRid, :elastic_clean, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230428500000 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:client) { ::Gitlab::Search::Client.new }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
    set_elasticsearch_migration_to :add_suffix_project_in_wiki_rid, including: false
    allow(migration).to receive(:client).and_return(client)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.throttle_delay).to eq(1.minute)
      expect(migration).to be_pause_indexing
      expect(migration).to be_space_requirements
    end
  end

  describe '.migrate' do
    context 'for batch run' do
      it 'sets migration_state task_id' do
        migration.migrate

        expect(migration.migration_state).to include(slice: 0, max_slices: 5)
        expect(migration.migration_state['task_id']).not_to be nil
      end

      it 'sets next slice and clears task_id after task check' do
        allow(migration).to receive(:reindexing_completed?).and_return(true)

        migration.set_migration_state(slice: 0, max_slices: 5, retry_attempt: 0, task_id: 'task_id')

        migration.migrate

        expect(migration.migration_state).to include(slice: 1, max_slices: 5, task_id: nil)
      end

      it 'resets retry_attempt clears task_id for the next slice' do
        allow(migration).to receive(:reindexing_completed?).and_return(true)

        migration.set_migration_state(slice: 0, max_slices: 5, retry_attempt: 5, task_id: 'task_id')

        migration.migrate

        expect(migration.migration_state).to match(slice: 1, max_slices: 5, retry_attempt: 0, task_id: nil)
      end

      context 'when reindexing is still in progress' do
        before do
          allow(migration).to receive(:reindexing_completed?).and_return(false)
        end

        it 'does nothing' do
          migration.set_migration_state(slice: 0, max_slices: 5, retry_attempt: 0, task_id: 'task_id')

          migration.migrate

          expect(client).not_to receive(:update_by_query)
        end
      end

      context 'with wikis in elastic' do
        # Create wikis on different projects to ensure they are spread across
        # all shards. If they all end up in 1 ES shard then they'll be migrated
        # in a single slice.
        let_it_be(:projects) { create_list(:project, 3, :wiki_repo, visibility_level: 0, wiki_access_level: 0) }

        before do
          projects.each do |project|
            project.wiki.create_page('index_page', 'Bla bla term')
            project.wiki.create_page('home_page', 'Bla bla term2')
            project.wiki.index_wiki_blobs
          end
          ensure_elasticsearch_index! # ensure objects are indexed
        end

        it 'migrates all wikis' do
          slices = 2
          migration.set_migration_state(slice: 0, max_slices: slices, retry_attempt: 0)
          migration.migrate

          10.times do
            break if migration.completed?

            migration.migrate
          end
          expect(migration.completed?).to be_truthy
          expect(client.search(index: "#{es_helper.target_name}-wikis")['hits']['hits'].map do |hit|
            hit['_source']['rid'].match(/wiki_project_[0-9].*/)
          end.all?).to be true
        end
      end
    end

    context 'for failed run' do
      context 'if exception is raised' do
        before do
          allow(migration).to receive(:client).and_return(client)
          allow(client).to receive(:update_by_query).and_raise(StandardError)
        end

        it 'increases retry_attempt and clears task_id' do
          migration.set_migration_state(slice: 0, max_slices: 2, retry_attempt: 1)

          expect { migration.migrate }.to raise_error(StandardError)
          expect(migration.migration_state).to match(slice: 0, max_slices: 2, retry_attempt: 2, task_id: nil)
        end

        it 'fails the migration after too many attempts' do
          migration.set_migration_state(slice: 0, max_slices: 2, retry_attempt: 30)

          migration.migrate

          expect(migration.migration_state).to match(
            slice: 0,
            max_slices: 2,
            retry_attempt: 30,
            halted: true,
            failed: true,
            halted_indexing_unpaused: false
          )
          expect(client).not_to receive(:update_by_query)
        end
      end

      context 'when elasticsearch failures' do
        context 'if total is not equal' do
          before do
            allow(helper).to receive(:task_status).and_return(
              {
                "completed" => true,
                "response" => {
                  "total" => 60, "updated" => 0, "created" => 45, "deleted" => 0, "failures" => []
                }
              }
            )
          end

          it 'raises an error and clears task_id' do
            migration.set_migration_state(slice: 0, max_slices: 2, retry_attempt: 0, task_id: 'task_id')

            expect { migration.migrate }.to raise_error(/total is not equal/)
            expect(migration.migration_state[:task_id]).to be_nil
          end
        end

        context 'when reindexing fails' do
          before do
            allow(helper).to receive(:task_status).with(task_id: 'task_id').and_return(
              {
                "completed" => true,
                "response" => {
                  "total" => 60,
                  "updated" => 0,
                  "created" => 0,
                  "deleted" => 0,
                  "failures" => [
                    { type: "es_rejected_execution_exception" }
                  ]
                }
              }
            )
          end

          it 'raises an error and clears task_id' do
            migration.set_migration_state(slice: 0, max_slices: 2, retry_attempt: 0, task_id: 'task_id')

            expect { migration.migrate }.to raise_error(/failed with/)
            expect(migration.migration_state[:task_id]).to be_nil
          end
        end
      end
    end
  end

  describe '.completed?' do
    subject { migration.completed? }

    let_it_be(:project) { create(:project, :wiki_repo, visibility_level: 0, wiki_access_level: 0) }

    before do
      project.wiki.create_page('index_page', 'Bla bla term')
      project.wiki.index_wiki_blobs
      ensure_elasticsearch_index! # ensure objects are indexed
    end

    context 'when there are no items which are missing project prefix in rid' do
      before do
        client.update_by_query(index: Elastic::Latest::WikiConfig.index_name,
          body: {
            script: { lang: 'painless',
                      source: "ctx._source.rid = ctx._source.rid.replace('wiki', 'wiki_project')" }
          }
        )
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when some items are missing project prefix in rid' do
      before do
        client.update_by_query(index: Elastic::Latest::WikiConfig.index_name,
          body: {
            script: { lang: 'painless',
                      source: "ctx._source.rid = ctx._source.rid.replace('wiki_project', 'wiki')" }
          }
        )
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe 'space_required_bytes' do
    subject { migration.space_required_bytes }

    before do
      allow(helper).to receive(:index_size_bytes).and_return(300)
    end

    it { is_expected.to eq(3) }
  end
end
