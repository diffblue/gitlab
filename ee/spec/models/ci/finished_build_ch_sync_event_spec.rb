# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::FinishedBuildChSyncEvent, type: :model, feature_category: :runner_fleet do
  describe 'validations' do
    subject(:event) { described_class.create!(build_id: 1, build_finished_at: 2.hours.ago) }

    it { is_expected.to validate_presence_of(:build_id) }
    it { is_expected.to validate_presence_of(:build_finished_at) }
  end

  describe '.pending' do
    subject(:scope) { described_class.pending }

    let_it_be(:event1) { described_class.create!(build_id: 1, build_finished_at: 2.hours.ago, processed: true) }
    let_it_be(:event2) { described_class.create!(build_id: 2, build_finished_at: 1.hour.ago) }
    let_it_be(:event3) { described_class.create!(build_id: 3, build_finished_at: 1.hour.ago, processed: true) }

    it { is_expected.to contain_exactly(event2) }
  end

  describe '.for_partition', :freeze_time do
    subject(:scope) { described_class.for_partition(partition) }

    let_it_be(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    before do
      described_class.create!(build_id: 1, build_finished_at: 2.hours.ago, processed: true)
      described_class.create!(build_id: 2, build_finished_at: 1.hour.ago, processed: true)

      travel(described_class::PARTITION_DURATION + 1.second)

      partition_manager.sync_partitions
      described_class.create!(build_id: 3, build_finished_at: 1.hour.ago)
    end

    context 'when partition = 1' do
      let(:partition) { 1 }

      it { is_expected.to match_array(described_class.where(build_id: [1, 2])) }
    end

    context 'when partition = 2' do
      let(:partition) { 2 }

      it { is_expected.to match_array(described_class.where(build_id: 3)) }
    end
  end

  describe 'sliding_list partitioning' do
    let(:partition_manager) { Gitlab::Database::Partitioning::PartitionManager.new(described_class) }
    let(:partitioning_strategy) { described_class.partitioning_strategy }

    around do |example|
      Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
        example.run
      end
    end

    describe 'next_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.next_partition_if.call(active_partition) }

      context 'when the partition is empty' do
        it { is_expected.to eq(false) }
      end

      context 'when the partition has records' do
        before do
          described_class.create!(build_id: 1, build_finished_at: 2.hours.ago, processed: true)
          described_class.create!(build_id: 2, build_finished_at: 1.minute.ago)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the first record of the partition is older than PARTITION_DURATION' do
        before do
          described_class.create!(build_id: 1, build_finished_at: (described_class::PARTITION_DURATION + 1.day).ago)
          described_class.create!(build_id: 2, build_finished_at: 1.minute.ago)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'detach_partition_if callback' do
      let(:active_partition) { partitioning_strategy.active_partition }

      subject(:value) { partitioning_strategy.detach_partition_if.call(active_partition) }

      context 'when the partition contains unprocessed records' do
        before do
          described_class.create!(build_id: 1, build_finished_at: 2.hours.ago, processed: true)
          described_class.create!(build_id: 2, build_finished_at: 1.minute.ago)
        end

        it { is_expected.to eq(false) }
      end

      context 'when the partition contains only processed records' do
        before do
          described_class.create!(build_id: 1, build_finished_at: 2.hours.ago, processed: true)
          described_class.create!(build_id: 2, build_finished_at: 1.minute.ago, processed: true)
        end

        it { is_expected.to eq(true) }
      end
    end

    describe 'the behavior of the strategy' do
      it 'moves records to new partitions as time passes', :freeze_time do
        # We start with partition 1
        expect(partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # it's not a day old yet so no new partitions are created
        partition_manager.sync_partitions

        expect(partitioning_strategy.current_partitions.map(&:value)).to eq([1])

        # add one record so the next partition will be created
        described_class.create!(build_id: 1, build_finished_at: Time.current)

        # after traveling forward a day
        travel(described_class::PARTITION_DURATION + 1.second)

        # a new partition is created
        partition_manager.sync_partitions

        expect(partitioning_strategy.current_partitions.map(&:value)).to eq([1, 2])

        # and we can insert to the new partition
        expect { described_class.create!(build_id: 5, build_finished_at: Time.current) }.not_to raise_error

        # after processing old records
        described_class.for_partition(1).update_all(processed: true)
        described_class.for_partition(2).update_all(processed: true)

        partition_manager.sync_partitions

        # the old one is removed
        expect(partitioning_strategy.current_partitions.map(&:value)).to eq([2])

        # and we only have the newly created partition left.
        expect(described_class.count).to eq(1)
      end
    end
  end
end
