# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230724070100_backfill_epics.rb')

RSpec.describe BackfillEpics, feature_category: :global_search do
  let(:version) { 20230724070100 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:index_name) { Epic.__elasticsearch__.index_name }

  subject(:migration) { described_class.new(version) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.throttle_delay).to eq(1.minute)
      expect(migration.pause_indexing?).to be_falsey
      expect(migration.retry_on_failure?).to be_truthy
      expect(migration.batch_size).to eq 1000
    end
  end

  describe 'integration test', :elastic, :sidekiq_inline do
    let_it_be(:epics) { create_list(:epic, 4) }

    before do
      set_elasticsearch_migration_to(version, including: false)
      ensure_elasticsearch_index!
      helper.delete_migration_record(migration)
    end

    it 'tracks all epic documents' do
      expect(migration).not_to be_completed

      expect(::Elastic::ProcessBookkeepingService).to receive(:track!)
        .with(*epics)
        .and_call_original
        .once

      subject.migrate

      expect(migration).to be_completed
    end

    it 'does not have N+1' do
      control_count = ActiveRecord::QueryRecorder.new { subject.migrate }

      create(:epic, group: create(:group, parent: create(:group)))
      ensure_elasticsearch_index!

      expect { subject.migrate }.not_to exceed_query_limit(control_count)
    end

    context 'with more than one iterations in a batch' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 3)
        allow(migration).to receive(:log).with(
          /Migration completed?/, { max_processed_id: anything, maximum_epic_id: anything }
        )
      end

      it 'tracks all epic documents in two iterations in one batch' do
        expect(migration).not_to be_completed

        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).twice.and_call_original

        expect(migration).to receive(:log).with(/Indexing epics starting from/, { id: 0 }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 1, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 2, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration).to be_completed
      end
    end

    context 'with more than one batches' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 1)
        stub_const("#{described_class.name}::ITERATIONS_PER_RUN", 2)
        allow(migration).to receive(:log).with(
          /Migration completed?/, { max_processed_id: anything, maximum_epic_id: anything }
        )
      end

      it 'tracks all epic documents in 4 iterations over two batches' do
        expect(migration).not_to be_completed

        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).exactly(4).times.and_call_original

        # First batch
        expect(migration).to receive(:log).with(/Indexing epics starting from/, { id: 0 }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 1, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 2, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration).not_to be_completed

        # Second batch
        expect(migration).to receive(:log).with(/Indexing epics starting from/, { id: anything }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 1, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Executing/, { iteration: 2, last_epic_id: anything }).once
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration).to be_completed
      end
    end

    context 'with elasticsearch_limit_indexing enabled' do
      let_it_be(:indexed_group) { create(:group) { |g| create(:elasticsearch_indexed_namespace, namespace: g) } }
      let_it_be(:unindexed_group) { create(:group) }
      let_it_be(:epics_for_indexed_group) { create_list(:epic, 3, group: indexed_group) }
      let_it_be(:epics_for_unindexed_group) { create_list(:epic, 4, group: unindexed_group) }

      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it 'tracks all epic documents for indexed groups only' do
        expect(migration).not_to be_completed

        expect(::Elastic::ProcessBookkeepingService).to receive(:track!)
          .with(*epics_for_indexed_group)
          .and_call_original
          .once

        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!)
          .with(*epics_for_unindexed_group)

        subject.migrate

        expect(migration).to be_completed
      end
    end
  end

  describe '#completed?', :elastic, :sidekiq_inline do
    before do
      set_elasticsearch_migration_to(version, including: false)
      ensure_elasticsearch_index!
      helper.delete_migration_record(migration)
    end

    it 'returns true if there are no epics' do
      expect(migration).to be_completed
    end

    context 'with epics' do
      let_it_be(:epics) { create_list(:epic, 3) }

      before do
        allow(migration).to receive(:migration_state).and_return({ max_processed_id: epics.last.id })
      end

      it 'returns true' do
        expect(migration).to be_completed
      end

      context "when the values don't match" do
        before do
          allow(migration).to receive(:migration_state).and_return({ max_processed_id: epics.last.id - 1 })
        end

        it 'returns false' do
          expect(migration).not_to be_completed
        end
      end
    end
  end
end
