# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::MultiDatabasePartitionManager, '#sync_partitions' do
  subject(:sync_partitions) { described_class.new(models).sync_partitions }

  let(:models) { [double, double] }

  let(:db_name1) { 'db1' }
  let(:db_name2) { 'db2' }

  let(:config1) { 'config1' }
  let(:config2) { 'config2' }
  let(:configurations) { double }

  let(:manager_class) { Gitlab::Database::Partitioning::PartitionManager }
  let(:manager1) { double('manager 1') }
  let(:manager2) { double('manager 2') }

  let(:original_config) { ActiveRecord::Base.connection_db_config }

  before do
    allow(configurations).to receive(:configs_for).with(env_name: Rails.env, name: db_name1).and_return(config1)
    allow(configurations).to receive(:configs_for).with(env_name: Rails.env, name: db_name2).and_return(config2)

    allow(Gitlab::Database).to receive(:db_config_names).and_return([db_name1, db_name2])

    allow(ActiveRecord::Base).to receive(:configurations).twice.and_return(configurations)
  end

  it 'syncs model partitions for each database connection' do
    expect(ActiveRecord::Base).to receive(:establish_connection).with(config1).ordered
    expect(manager_class).to receive(:new).with(models).and_return(manager1).ordered
    expect(manager1).to receive(:sync_partitions).ordered

    expect(ActiveRecord::Base).to receive(:establish_connection).with(config2).ordered
    expect(manager_class).to receive(:new).with(models).and_return(manager2).ordered
    expect(manager2).to receive(:sync_partitions).ordered

    expect(ActiveRecord::Base).to receive(:establish_connection).with(original_config).ordered

    sync_partitions
  end

  context 'if an error is raised' do
    it 'restores the original connection' do
      expect(ActiveRecord::Base).to receive(:establish_connection).with(config1).ordered
      expect(manager_class).to receive(:new).with(models).and_return(manager1).ordered
      expect(manager1).to receive(:sync_partitions).ordered.and_raise(RuntimeError)

      expect(ActiveRecord::Base).to receive(:establish_connection).with(original_config).ordered

      expect { sync_partitions }.to raise_error(RuntimeError)
    end
  end

  context 'if no models are given' do
    let(:models) { [] }

    it 'does nothing, changing no connections' do
      expect(ActiveRecord::Base).not_to receive(:establish_connection)
      expect(manager_class).not_to receive(:new)

      sync_partitions
    end
  end
end
