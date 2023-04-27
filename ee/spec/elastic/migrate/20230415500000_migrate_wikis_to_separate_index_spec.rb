# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230415500000_migrate_wikis_to_separate_index.rb')

RSpec.describe MigrateWikisToSeparateIndex, feature_category: :global_search do
  let(:version) { 20230415500000 }
  let(:migration) { described_class.new(version) }
  let(:index_name) { "#{es_helper.target_name}-wikis" }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.throttle_delay).to eq(1.minute)
      expect(migration.pause_indexing?).to be_truthy
      expect(migration.space_requirements?).to be_truthy
    end
  end

  describe '.migrate', :elastic_clean, :sidekiq_inline do
    before do
      set_elasticsearch_migration_to :migrate_wikis_to_separate_index, including: false
    end

    context 'for initial launch' do
      before do
        es_helper.delete_index(index_name: es_helper.target_index_name(target: index_name))
      end

      it 'creates an index and sets migration_state' do
        expect { migration.migrate }.to change { es_helper.alias_exists?(name: index_name) }.from(false).to(true)

        expect(migration.migration_state).to include(slice: 0, max_slices: 5)
      end
    end

    context 'for batch run' do
      it 'sets migration_state task_id' do
        allow(migration).to receive(:reindex).and_return('task_id')

        migration.set_migration_state(slice: 0, max_slices: 5, retry_attempt: 0)

        migration.migrate

        expect(migration.migration_state).to include(slice: 0, max_slices: 5, task_id: 'task_id')
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

          expect(migration).not_to receive(:reindex)
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
          expect(es_helper.documents_count(index_name: "#{es_helper.target_name}-wikis")).to eq(projects.count * 2)
        end
      end
    end

    context 'for failed run' do
      context 'if exception is raised' do
        before do
          allow(migration).to receive(:reindex).and_raise(StandardError)
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
          expect(migration).not_to receive(:reindex)
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

    let(:original_count) { 5 }

    before do
      allow(helper).to receive(:refresh_index).and_return(true)
      allow(migration).to receive(:original_documents_count).and_return(original_count)
      allow(migration).to receive(:new_documents_count).and_return(new_count)
    end

    context 'when counts are equal' do
      let(:new_count) { original_count }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when counts are not equal' do
      let(:new_count) { original_count - 1 }

      it 'returns true' do
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
