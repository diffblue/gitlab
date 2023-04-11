# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Migration, :elastic do
  let(:logger) { double('Gitlab::Elasticsearch::Logger') }
  let(:migration_class) do
    Class.new(described_class) do
      def migrate
        log "number_of_nodes: #{client.cluster.health['number_of_nodes']}"

        raise 'Index does not exist' unless helper.migrations_index_exists?
      end
    end
  end

  let(:version) { 20201105181100 }
  let(:migration) { migration_class.new(version) }
  let(:bare_migration) { described_class.new(version) }

  before do
    allow(::Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger)
  end

  describe '#migrate' do
    it 'executes method' do
      expect(logger).to receive(:info).with(a_hash_including('message' => /number_of_nodes/))
      expect { migration.migrate }.not_to raise_error
    end

    it 'raises exception for original class' do
      expect { bare_migration.migrate }.to raise_error(NotImplementedError)
    end
  end

  describe '#completed?' do
    it 'raises exception for original class' do
      expect { bare_migration.completed? }.to raise_error(NotImplementedError)
    end
  end

  describe '#space_required_bytes' do
    it 'raises exception for original class' do
      expect { bare_migration.space_required_bytes }.to raise_error(NotImplementedError)
    end
  end
end
