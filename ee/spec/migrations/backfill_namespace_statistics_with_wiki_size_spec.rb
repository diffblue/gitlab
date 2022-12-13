# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNamespaceStatisticsWithWikiSize, feature_category: :wiki do
  let!(:shards) { table(:shards) }
  let!(:shard) { shards.create!(id: 1, name: 'default') }
  let!(:groups) { table(:namespaces) }
  let!(:group1) { groups.create!(id: 10, name: 'test1', path: 'test1', type: 'Group') }
  let!(:group2) { groups.create!(id: 20, name: 'test2', path: 'test2', type: 'Group') }
  let!(:group3) { groups.create!(id: 30, name: 'test3', path: 'test3', type: 'Group') }
  let!(:group4) { groups.create!(id: 40, name: 'test4', path: 'test4', type: 'Group') }
  let!(:group_wiki_repository) { table(:group_wiki_repositories) }
  let!(:group1_repo) { group_wiki_repository.create!(shard_id: 1, group_id: 10, disk_path: 'foo1') }
  let!(:group2_repo) { group_wiki_repository.create!(shard_id: 1, group_id: 20, disk_path: 'foo2') }
  let!(:group3_repo) { group_wiki_repository.create!(shard_id: 1, group_id: 30, disk_path: 'foo3') }

  describe '#up' do
    it 'correctly schedules background migrations' do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          aggregate_failures do
            expect(described_class::MIGRATION)
              .to be_scheduled_migration([10, 20], ['wiki_size'])

            expect(described_class::MIGRATION)
              .to be_scheduled_delayed_migration(2.minutes, [30], ['wiki_size'])

            expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          end
        end
      end
    end
  end
end
