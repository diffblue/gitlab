# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::IndexCurator do
  subject(:curator) { described_class.new(settings) }

  let(:settings) { {} }
  let(:client) { Gitlab::Search::Client.new }
  let(:stubbed_helper) { instance_double(::Gitlab::Elastic::Helper) }
  let(:stubbed_logger) { instance_double(::Gitlab::Elasticsearch::Logger) }

  let(:index_info) do
    { "health" => "yellow",
      "status" => "open",
      "index" => "gitlab-development-20220915-0422",
      "uuid" => "jxAa-nq-QA6ZIhmKfSmnnw",
      "pri" => "5",
      "rep" => "1",
      "docs.count" => "98",
      "docs.deleted" => "0",
      "store.size" => "108.7",
      "pri.store.size" => "108.7" }
  end

  describe '.curate' do
    subject(:stubbed_curator) { instance_double(described_class) }

    let(:index_one) { instance_double(Hash) }
    let(:index_two) { instance_double(Hash) }
    let(:index_three) { instance_double(Hash) }

    before do
      allow(described_class).to receive(:new).and_return(stubbed_curator)
    end

    it 'rolls over the indices that need to be rolled over' do
      allow(stubbed_curator).to receive(:preflight_checks!)
      allow(stubbed_curator).to receive(:indices).and_return([index_one, index_two, index_three])
      allow(stubbed_curator).to receive(:should_rollover?).and_return false
      allow(stubbed_curator).to receive(:should_rollover?).with(index_two).and_return true

      expect(stubbed_curator).to receive(:rollover_index).with(index_two)

      described_class.curate
    end

    it 'logs any exceptions' do
      err = ArgumentError.new("boom")
      expect(stubbed_curator).to receive(:preflight_checks!).and_raise err
      expect(stubbed_curator).to receive(:log_exception).with err

      described_class.curate
    end

    it 'does not do any rollovers if preflight checks fail' do
      allow(stubbed_curator).to receive(:helper).and_return stubbed_helper
      allow(stubbed_helper).to receive(:pending_migrations?).and_return true
      allow(stubbed_curator).to receive(:indices).and_return([index_one])
      expect(stubbed_curator).not_to receive(:rollover_index)
    end
  end

  describe '#settings' do
    it 'has defaults' do
      expect(curator.settings).to eq(described_class::DEFAULT_SETTINGS)
    end

    context 'when specific values are passed' do
      let(:settings) { { ignore_patterns: ['foo'] } }

      it 'merges specific values' do
        expect(curator.settings[:ignore_patterns]).to eq(settings[:ignore_patterns])
      end
    end

    context 'when max_docs_demoninator is <= 0' do
      let(:settings) { { max_docs_denominator: 0 } }

      it 'raises an argument error' do
        expect { curator }.to raise_error ArgumentError
      end
    end
  end

  describe '#rollover_index' do
    let(:rollover_info) do
      { from: "gitlab-development-20220915-0422", to: "gitlab-development-20220915-0423" }
    end

    context 'when dry_run is not enabled' do
      it 'updates settings and returns rollover info' do
        expect(curator).to receive(:create_new_index_with_same_settings)
        expect(curator).to receive(:update_aliases)

        expect(curator.rollover_index(index_info)).to eq(rollover_info)
      end
    end

    context 'when dry_run is enabled' do
      let(:settings) { { dry_run: true } }

      it 'logs a statement, does not do anything, and returns rollover info' do
        expect(curator).not_to receive(:create_new_index_with_same_settings)
        expect(curator).not_to receive(:update_aliases)
        allow(curator).to receive(:logger).and_return(stubbed_logger)

        expect(stubbed_logger).to receive(:info).with(
          message: "[DRY RUN]: would have rolled over => #{rollover_info}",
          class: "Gitlab::Search::IndexCurator"
        )

        expect(curator.rollover_index(index_info)).to eq(rollover_info)
      end
    end
  end

  describe '#rollover_index integration test' do
    let(:index_name) { "foo-index-0001" }
    let(:new_index_name) { "foo-index-0002" }
    let(:alias_name) { "foo-index" }
    let(:index_info) { get_index_info(index: index_name) }

    before do
      client.index(index: index_name, body: { bar: "baz" })
      client.indices.put_alias(name: alias_name, index: index_name)
    end

    after do
      client.indices.delete(index: index_name, ignore_unavailable: true)
      client.indices.delete(index: new_index_name, ignore_unavailable: true)

      if client.indices.exists_alias(name: alias_name, index: index_name)
        client.indices.delete_alias(name: alias_name, index: index_name)
      end

      if client.indices.exists_alias(name: alias_name, index: new_index_name)
        client.indices.delete_alias(name: alias_name, index: new_index_name)
      end
    end

    context 'when write alias is not specified' do
      it 'creates another index and updates write alias' do
        expect(get_alias_info(index: index_name).dig(alias_name, "is_write_index")).to be_nil
        curator.rollover_index(index_info)
        expect(client.indices.exists(index: new_index_name)).to be_truthy
        expect(get_alias_info(index: index_name).dig(alias_name, "is_write_index")).to be_falsey
        expect(get_alias_info(index: new_index_name).dig(alias_name, "is_write_index")).to be_truthy
      end
    end

    context 'when write alias is already specified' do
      before do
        client.indices.put_alias(name: alias_name, index: index_name, body: { is_write_index: true })
      end

      it 'creates another index and updates write alias' do
        expect(get_alias_info(index: index_name).dig(alias_name, "is_write_index")).to be_truthy
        curator.rollover_index(index_info)
        expect(client.indices.exists(index: new_index_name)).to be_truthy
        expect(get_alias_info(index: index_name).dig(alias_name, "is_write_index")).to be_falsey
        expect(get_alias_info(index: new_index_name).dig(alias_name, "is_write_index")).to be_truthy
      end
    end
  end

  describe '#should_rollover?' do
    using RSpec::Parameterized::TableSyntax

    where(:should_ignore_index, :too_few_docs, :too_many_docs, :primary_shard_size_too_big, :expected_value) do
      false | false | false | false | false
      false | false | true  | true  | true
      false | false | true  | false | true
      false | false | false | true  | true
      false | true  | false | true  | false
      true  | false | true  | true  | false
    end

    with_them do
      it 'returns correct value' do
        allow(curator).to receive(:should_ignore_index?).and_return should_ignore_index
        allow(curator).to receive(:too_many_docs?).and_return too_many_docs
        allow(curator).to receive(:too_few_docs?).and_return too_few_docs
        allow(curator).to receive(:primary_shard_size_too_big?).and_return primary_shard_size_too_big

        expect(curator.should_rollover?(index_info)).to eq(expected_value)
      end
    end
  end

  describe '#too_many_docs?' do
    context 'when document count is saturated' do
      let(:settings) { { max_docs_denominator: 10, max_docs_shard_count: 1 } }

      it 'returns true' do
        expect(curator).to be_too_many_docs(index_info)
      end
    end

    context 'when document count is not saturated' do
      let(:settings) { { max_docs_denominator: 5_000_000, max_docs_shard_count: 5 } }

      it 'returns false' do
        expect(curator).not_to be_too_many_docs(index_info)
      end
    end
  end

  describe '#too_few_docs?' do
    context 'when minimum threshold is not met' do
      let(:settings) { { min_docs_before_rollover: 100 } }

      it 'returns true' do
        expect(curator).to be_too_few_docs(index_info)
      end
    end

    context 'when minimum threshold is met' do
      let(:settings) { { min_docs_before_rollover: index_info["docs.count"].to_i } }

      it 'returns false' do
        expect(curator).not_to be_too_few_docs(index_info)
      end
    end
  end

  describe '#primary_shard_size_too_big?' do
    context 'when pri.store.size value is greater than max size' do
      let(:settings) { { max_shard_size_gb: 1 } }

      it 'returns true' do
        expect(curator).to be_primary_shard_size_too_big(index_info)
      end
    end

    context 'when pri.store.size value is less than max size' do
      let(:settings) { { max_shard_size_gb: 1_000_000 } }

      it 'returns false' do
        expect(curator).not_to be_primary_shard_size_too_big(index_info)
      end
    end
  end

  describe '#should_ignore_index?' do
    context 'when index name matches one of the ignore patterns' do
      let(:settings) { { ignore_patterns: [/gitlab-dev/] } }

      it 'returns true' do
        expect(curator).to be_should_ignore_index(index_info)
      end
    end

    context 'when none of the ignore patterns match the index name' do
      let(:settings) { { ignore_patterns: ['noop'] } }

      it 'returns false' do
        expect(curator).not_to be_should_ignore_index(index_info)
      end
    end
  end

  describe '#increment_index_name' do
    it 'returns an index name with number from last four digits incremented' do
      expect(curator.increment_index_name("foobar-0001")).to eq("foobar-0002")
      expect(
        curator.increment_index_name("gitlab-development-issues-20220301-0823")
      ).to eq("gitlab-development-issues-20220301-0824")
      expect(curator.increment_index_name("0999")).to eq("1000")
    end

    it 'starts a number suffix if one does not already exist' do
      expect(curator.increment_index_name("foo")).to eq("foo-0002")
      expect(curator.increment_index_name("gitlab-development-migrations")).to eq("gitlab-development-migrations-0002")
    end
  end

  describe '#indices' do
    it 'returns write indices from aliases' do
      aliases = [
        { 'index' => 'foo', 'is_write_index' => '-' },
        { 'index' => 'bar', 'is_write_index' => 'true' },
        { 'index' => 'baz', 'is_write_index' => 'false' }
      ]
      allow(curator.client).to receive_message_chain(:cat, :aliases).and_return(aliases)

      indices = instance_double(Array)
      expect(curator.client).to receive_message_chain(:cat, :indices).with(
        index: %w[foo bar], expand_wildcards: 'open', format: 'json', pri: true, bytes: 'gb'
      ).and_return indices

      expect(curator.indices).to eq(indices)
    end
  end

  describe '#client' do
    it 'is a Gitlab::Search::Client' do
      expect(curator.client).to be_a ::Gitlab::Search::Client
    end
  end

  describe '#preflight_checks!' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(curator).to receive(:helper).and_return stubbed_helper
    end

    where(:pending_migrations, :indexing_paused, :should_fail) do
      true  | false | true
      false | true  | true
      true  | true  | true
      false | false | false
    end

    with_them do
      it 'raises an ArgumentError if checks fail' do
        allow(stubbed_helper).to receive(:pending_migrations?).and_return(pending_migrations)
        allow(stubbed_helper).to receive(:indexing_paused?).and_return(indexing_paused)

        if should_fail
          expect { curator.preflight_checks! }.to raise_error(ArgumentError, /preflight checks failed/)
        else
          expect { curator.preflight_checks! }.not_to raise_error
        end
      end
    end
  end

  describe 'log_exception' do
    it 'logs an error with correct labels' do
      err = ArgumentError.new("boom")

      allow(curator).to receive(:logger).and_return stubbed_logger
      expect(stubbed_logger).to receive(:error).with(
        search_curation_status: "error",
        error: "boom",
        message: "Search curation",
        class: "Gitlab::Search::IndexCurator"
      )

      curator.log_exception(err)
    end
  end
end

def get_index_info(index:)
  client.cat.indices(index: index, format: 'json').first
end

def get_alias_info(index:)
  client.indices.get(index: index).dig(index, 'aliases')
end
