# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MigrationRecord, :elastic_clean do
  using RSpec::Parameterized::TableSyntax

  let(:record) { described_class.new(version: Time.now.to_i, name: 'ExampleMigration', filename: nil) }

  describe '#save!' do
    it 'creates an index if it is not found' do
      es_helper.delete_migrations_index

      expect { record.save!(completed: true) }.to raise_error(/index is not found/)
    end

    it 'sets the migration name' do
      record.save!(completed: false)

      expect(record.load_from_index.dig('_source', 'name')).to eq(record.name)
    end

    it 'sets the started_at' do
      record.save!(completed: false)

      expect(record.load_from_index.dig('_source', 'started_at')).not_to be_nil
    end

    it 'does not update started_at on subsequent saves' do
      record.save!(completed: false)

      real_started_at = record.load_from_index.dig('_source', 'started_at')

      record.save!(completed: false)

      expect(record.load_from_index.dig('_source', 'started_at')).to eq(real_started_at)
    end

    it 'sets completed_at when completed' do
      record.save!(completed: true)

      expect(record.load_from_index.dig('_source', 'completed_at')).not_to be_nil
    end

    it 'does not set completed_at when not completed' do
      record.save!(completed: false)

      expect(record.load_from_index.dig('_source', 'completed_at')).to be_nil
    end
  end

  describe '#load_from_index' do
    it 'does not raise an exception when connection refused' do
      allow(Gitlab::Elastic::Helper.default).to receive(:get).and_raise(Faraday::ConnectionFailed)

      expect(record.load_from_index).to be_nil
    end

    it 'does not raise an exception when record does not exist' do
      allow(Gitlab::Elastic::Helper.default).to receive(:get).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)

      expect(record.load_from_index).to be_nil
    end
  end

  describe '#halt' do
    it 'sets state for halted and halted_indexing_unpaused' do
      record.halt

      expect(record.load_from_index.dig('_source', 'state', 'halted')).to be_truthy
      expect(record.load_from_index.dig('_source', 'state', 'halted_indexing_unpaused')).to be_falsey
    end

    it 'sets state with additional options if passed' do
      record.halt(hello: 'world', good: 'bye')

      expect(record.load_from_index.dig('_source', 'state', 'hello')).to eq('world')
      expect(record.load_from_index.dig('_source', 'state', 'good')).to eq('bye')
    end
  end

  describe '#fail' do
    it 'calls halt with failed: true' do
      expect(record).to receive(:halt).with({ failed: true, foo: :bar })

      record.fail({ foo: :bar })
    end
  end

  describe '#started?' do
    it 'changes on object save' do
      expect { record.save!(completed: true) }.to change { record.started? }.from(false).to(true)
    end
  end

  describe '.load_versions' do
    let(:completed_versions) { 1.upto(5).map { |i| described_class.new(version: i, name: i, filename: nil) } }
    let(:in_progress_migration) { described_class.new(version: 10, name: 10, filename: nil) }

    before do
      es_helper.delete_migrations_index
      es_helper.create_migrations_index
      completed_versions.each { |migration| migration.save!(completed: true) }
      in_progress_migration.save!(completed: false)

      es_helper.refresh_index(index_name: es_helper.migrations_index_name)
    end

    it 'loads all records' do
      expect(described_class.load_versions(completed: true)).to match_array(completed_versions.map(&:version))
      expect(described_class.load_versions(completed: false)).to contain_exactly(in_progress_migration.version)
    end

    it 'raises an exception if no index present' do
      es_helper.delete_migrations_index

      expect { described_class.load_versions(completed: true) }.to raise_exception(Elasticsearch::Transport::Transport::Errors::NotFound)
      expect { described_class.load_versions(completed: false) }.to raise_exception(Elasticsearch::Transport::Transport::Errors::NotFound)
    end

    it 'raises an exception when exception is raised' do
      allow(Gitlab::Elastic::Helper.default.client).to receive(:search).and_raise(Faraday::ConnectionFailed)

      expect { described_class.load_versions(completed: true) }.to raise_exception(StandardError)
      expect { described_class.load_versions(completed: false) }.to raise_exception(StandardError)
    end

    it 'has a size constant bigger than the number of migrations' do
      # if this spec fails, bump the constant's value:
      # https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/elastic/migration_record.rb#L7

      elastic_migration_path = 'ee/elastic/migrate/*.rb'
      number_of_migrations = Dir[Rails.root.join(elastic_migration_path)].length
      expect(described_class::ELASTICSEARCH_SIZE).to be > number_of_migrations
    end
  end

  describe '#current_migration' do
    before do
      allow(Elastic::DataMigrationService).to receive(:migrations).and_return([record])
      allow(described_class).to receive(:completed_versions).and_return(completed_migrations.map(&:version))
    end

    context 'when there is an unexecuted migration' do
      let(:completed_migrations) { [] }

      it 'returns the correct migration' do
        expect(described_class.current_migration).to eq record
      end
    end

    context 'when there are no uncompleted migrations' do
      let(:completed_migrations) { [record] }

      it 'returns nil' do
        expect(described_class.current_migration).to be_nil
      end
    end
  end

  describe '#running?' do
    before do
      allow(record).to receive(:halted?).and_return(halted)
      allow(record).to receive(:started?).and_return(started)
      allow(record).to receive(:completed?).and_return(completed)
    end

    where(:started, :halted, :completed, :expected) do
      false | false | false | false
      true  | false | false | true
      true  | true  | false | false
      true  | true  | true  | false
      true  | false | true  | false
    end

    with_them do
      it 'returns the expected result' do
        expect(record.running?).to eq(expected)
      end
    end
  end

  describe '#stopped?' do
    before do
      allow(record).to receive(:halted?).and_return(halted)
      allow(record).to receive(:completed?).and_return(completed)
    end

    where(:halted, :completed, :expected) do
      false | false | false
      false | true  | true
      true  | false | true
      true  | true  | true
    end

    with_them do
      it 'returns the expected result' do
        expect(record.stopped?).to eq(expected)
      end
    end
  end
end
