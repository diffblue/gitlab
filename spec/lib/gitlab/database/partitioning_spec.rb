# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning do
  describe '.sync_partitions' do
    let(:partition_manager_class) { described_class::MultiDatabasePartitionManager }
    let(:partition_manager) { double('partition manager') }

    context 'when no partitioned models are given' do
      it 'calls the partition manager with the default partitions' do
        expect(partition_manager_class).to receive(:new)
          .with(described_class.default_partitioned_models)
          .and_return(partition_manager)

        expect(partition_manager).to receive(:sync_partitions)

        described_class.sync_partitions
      end
    end

    context 'when partitioned models are given' do
      it 'calls the partition manager with the given partitions' do
        models = ['my special model']

        expect(partition_manager_class).to receive(:new)
          .with(models)
          .and_return(partition_manager)

        expect(partition_manager).to receive(:sync_partitions)

        described_class.sync_partitions(models)
      end
    end
  end

  describe '.default_partitioned_models' do
    subject(:default_partitioned_models) { described_class.default_partitioned_models }

    it 'returns all core and EE models' do
      core_models = described_class.core_partitioned_models
      ee_models = described_class.ee_partitioned_models

      expect(default_partitioned_models).to eq(core_models.union(ee_models))
    end
  end
end
