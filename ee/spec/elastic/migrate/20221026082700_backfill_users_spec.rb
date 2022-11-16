# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20221026082700_backfill_users.rb')

RSpec.describe BackfillUsers, :elastic, :sidekiq_inline do
  let(:version) { 20221026082700 }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:index_name) { User.__elasticsearch__.index_name }

  subject(:migration) { described_class.new(version) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
    set_elasticsearch_migration_to(version, including: false)
    ensure_elasticsearch_index!
    helper.delete_migration_record(migration)
  end

  describe 'integration test' do
    let_it_be(:users) { create_list(:user, 4) }

    it 'tracks all user documents' do
      expect(migration.completed?).to be_falsey # rubocop:disable RSpec/PredicateMatcher

      expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).once.and_call_original do |*refs|
        expect(refs.count).to eq(4)
      end

      subject.migrate

      expect(migration.completed?).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    context 'with more than one iterations in a batch' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 3)
        allow(migration).to receive(:log).with(/Migration completed?/)
      end

      it 'tracks all user documents in two iterations in one batch' do
        expect(migration.completed?).to be_falsey # rubocop:disable RSpec/PredicateMatcher

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).twice.and_call_original do |*refs|
          expect(refs.count).to eq(4)
        end

        expect(migration).to receive(:log).with(/Indexing users starting from id/).once
        expect(migration).to receive(:log).with(/Executing iteration/).twice
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration.completed?).to be_truthy # rubocop:disable RSpec/PredicateMatcher
      end
    end

    context 'with more than one batches' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 1)
        stub_const("#{described_class.name}::ITERATIONS_PER_RUN", 2)
        allow(migration).to receive(:log).with(/Migration completed?/)
      end

      it 'tracks all user documents in 4 iterations over two batches' do
        expect(migration.completed?).to be_falsey # rubocop:disable RSpec/PredicateMatcher

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).exactly(4).times
        .and_call_original do |*refs|
          expect(refs.count).to eq(4)
        end

        # First batch
        expect(migration).to receive(:log).with(/Indexing users starting from id/).once
        expect(migration).to receive(:log).with(/Executing iteration/).twice
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration.completed?).to be_falsey # rubocop:disable RSpec/PredicateMatcher

        # Second batch
        expect(migration).to receive(:log).with(/Indexing users starting from id/).once
        expect(migration).to receive(:log).with(/Executing iteration/).twice
        expect(migration).to receive(:log).with(/Setting migration_state to/).once

        subject.migrate

        expect(migration.completed?).to be_truthy # rubocop:disable RSpec/PredicateMatcher
      end
    end
  end

  describe '#completed?' do
    before do
      allow(User).to receive(:maximum).with(:id).and_return(5)
      allow(migration).to receive(:migration_state).and_return({ max_processed_id: 5 })
    end

    it 'returns true' do
      expect(migration.completed?).to be_truthy # rubocop:disable RSpec/PredicateMatcher
    end

    context "when the values don't match" do
      before do
        allow(User).to receive(:maximum).with(:id).and_return(10)
        allow(migration).to receive(:migration_state).and_return({ max_processed_id: 5 })
      end

      it 'returns false' do
        expect(migration.completed?).to be_falsey # rubocop:disable RSpec/PredicateMatcher
      end
    end
  end

  describe '#document_type' do
    it 'is :user' do
      expect(migration.document_type).to eq(:user)
    end
  end
end
