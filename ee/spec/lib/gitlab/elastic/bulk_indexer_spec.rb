# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::BulkIndexer, :elastic, :clean_gitlab_redis_shared_state do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:other_issue) { create(:issue, project: issue.project) }

  let(:project) { issue.project }

  let(:logger) { ::Gitlab::Elasticsearch::Logger.build }

  subject(:indexer) { described_class.new(logger: logger) }

  let(:es_client) { indexer.client }

  let(:issue_as_ref) { ref(issue) }
  let(:issue_as_json_with_times) { issue.__elasticsearch__.as_indexed_json }
  let(:issue_as_json) { issue_as_json_with_times.except('created_at', 'updated_at') }
  let(:other_issue_as_ref) { ref(other_issue) }

  # Because there are two indices, one rolled over and one active,
  # there is an additional op for each index.
  #
  # Whatever the json payload bytesize is, it will ultimately be multiplied
  # by the total number of indices. We add an additional 0.5 to the overflow
  # factor to simulate the bulk_limit being exceeded in tests.
  let(:bulk_limit_overflow_factor) { 2.5 }

  describe '#process' do
    it 'returns bytesize for the indexing operation and data' do
      bytesize = instance_double(Integer)
      allow(indexer).to receive(:submit).and_return(bytesize)

      expect(indexer.process(issue_as_ref)).to eq(bytesize)
    end

    it 'returns bytesize when DocumentShouldBeDeletedFromIndexException is raised' do
      bytesize = instance_double(Integer)
      allow(indexer).to receive(:submit).and_return(bytesize)

      rec = issue_as_ref.database_record
      allow(rec.__elasticsearch__)
        .to receive(:as_indexed_json)
        .and_raise ::Elastic::Latest::DocumentShouldBeDeletedFromIndexError.new(rec.class.name, rec.id)

      expect(indexer.process(issue_as_ref)).to eq(bytesize)
    end

    it 'does not send a bulk request per call' do
      expect(es_client).not_to receive(:bulk)

      indexer.process(issue_as_ref)
    end

    it 'sends the action and source in the same request' do
      set_bulk_limit(indexer, 1)
      indexer.process(issue_as_ref)
      allow(es_client).to receive(:bulk).and_return({})

      indexer.process(issue_as_ref)

      expect(es_client)
        .to have_received(:bulk)
        .with(body: [kind_of(String), kind_of(String)])
      expect(indexer.failures).to be_empty
    end

    it 'sends a bulk request before adding an item that exceeds the bulk limit' do
      bulk_limit_bytes = (issue_as_json_with_times.to_json.bytesize * bulk_limit_overflow_factor).to_i
      set_bulk_limit(indexer, bulk_limit_bytes)
      indexer.process(issue_as_ref)
      allow(es_client).to receive(:bulk).and_return({})

      indexer.process(issue_as_ref)

      expect(es_client).to have_received(:bulk) do |args|
        body_bytesize = args[:body].sum(&:bytesize)
        expect(body_bytesize).to be <= bulk_limit_bytes
      end

      expect(indexer.failures).to be_empty
    end
  end

  describe '#flush' do
    it 'completes a bulk' do
      indexer.process(issue_as_ref)

      # The es_client will receive three items in bulk request for a single ref:
      # 1) The bulk index header, ie: { "index" => { "_index": "gitlab-issues" } }
      # 2) The payload of the actual document to write index
      # 3) The delete request for document in rolled over index
      expect(es_client)
        .to receive(:bulk)
        .with(body: [kind_of(String), kind_of(String), kind_of(String)])
        .and_return({})

      expect(indexer.flush).to be_empty
    end

    it 'fails documents that elasticsearch refuses to accept' do
      # Indexes with uppercase characters are invalid
      allow(other_issue_as_ref.database_record.__elasticsearch__)
        .to receive(:index_name)
        .and_return('Invalid')

      indexer.process(issue_as_ref)
      indexer.process(other_issue_as_ref)

      expect(indexer.flush).to contain_exactly(other_issue_as_ref)
      expect(indexer.failures).to contain_exactly(other_issue_as_ref)

      refresh_index!

      expect(search_one(Issue)).to have_attributes(issue_as_json)
    end

    it 'fails all documents on exception' do
      expect(es_client).to receive(:bulk) { raise 'An exception' }

      indexer.process(issue_as_ref)
      indexer.process(other_issue_as_ref)

      # Since there are two indices, one rolled over and one active
      # we can expect to have double the instances of failed refs
      expect(indexer.flush).to contain_exactly(issue_as_ref, issue_as_ref, other_issue_as_ref, other_issue_as_ref)
      expect(indexer.failures).to contain_exactly(issue_as_ref, issue_as_ref, other_issue_as_ref, other_issue_as_ref)
    end

    it 'fails a document correctly on exception after adding an item that exceeded the bulk limit' do
      bulk_limit_bytes = (issue_as_json_with_times.to_json.bytesize * bulk_limit_overflow_factor).to_i
      set_bulk_limit(indexer, bulk_limit_bytes)
      indexer.process(issue_as_ref)
      allow(es_client).to receive(:bulk).and_return({})

      indexer.process(issue_as_ref)

      expect(es_client).to have_received(:bulk) do |args|
        body_bytesize = args[:body].sum(&:bytesize)
        expect(body_bytesize).to be <= bulk_limit_bytes
      end

      expect(es_client).to receive(:bulk) { raise 'An exception' }

      # Since there are two indices, one rolled over and one active
      # we can expect to have double the instances of failed refs
      expect(indexer.flush).to contain_exactly(issue_as_ref, issue_as_ref)
      expect(indexer.failures).to contain_exactly(issue_as_ref, issue_as_ref)
    end

    context 'indexing an issue' do
      it 'adds the issue to the index' do
        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty

        refresh_index!

        expect(search_one(Issue)).to have_attributes(issue_as_json)
      end

      it 'reindexes an unchanged issue' do
        ensure_elasticsearch_index!

        expect(es_client).to receive(:bulk).and_call_original

        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty
      end

      it 'reindexes a changed issue' do
        ensure_elasticsearch_index!
        issue.update!(title: 'new title')

        expect(issue_as_json['title']).to eq('new title')

        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty

        refresh_index!

        expect(search_one(Issue)).to have_attributes(issue_as_json)
      end

      it 'deletes the issue from the index if DocumentShouldBeDeletedFromIndexException is raised' do
        database_record = issue_as_ref.database_record
        allow(database_record.__elasticsearch__)
          .to receive(:as_indexed_json)
                .and_raise ::Elastic::Latest::DocumentShouldBeDeletedFromIndexError.new(database_record.class.name, database_record.id)

        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty

        refresh_index!

        expect(search(Issue, '*').size).to eq(0)
      end

      context 'when aliases are being used' do
        let(:alias_name) { "gitlab-test-issues" }
        let(:read_index) { "gitlab-test-issues-20220915-0822" }
        let(:write_index) { "gitlab-test-issues-20220915-0823" }

        before do
          allow(es_client).to receive_message_chain(:indices, :get_alias)
            .with(index: alias_name).and_return(
              {
                read_index => { "aliases" => { alias_name => {} } },
                write_index => { "aliases" => { alias_name => { "is_write_index" => true } } }
              }
            )
        end

        it 'adds a delete op for each read index' do
          expect(indexer).to receive(:delete).with(issue_as_ref, index_name: read_index)
          expect(indexer).not_to receive(:delete).with(issue_as_ref, index_name: write_index)

          indexer.process(issue_as_ref)

          expect(indexer.flush).to be_empty
        end
      end

      context 'when there has not been a alias rollover yet' do
        let(:alias_name) { "gitlab-test-issues" }
        let(:single_index) { "gitlab-test-issues-20220915-0822" }

        before do
          allow(es_client).to receive_message_chain(:indices, :get_alias)
            .with(index: alias_name).and_return(
              { single_index => { "aliases" => { alias_name => {} } } }
            )
        end

        it 'does not do any delete ops' do
          expect(indexer).not_to receive(:delete)

          indexer.process(issue_as_ref)

          expect(indexer.flush).to be_empty
        end
      end

      context 'when feature flag `search_index_curation` is disabled' do
        before do
          stub_feature_flags(search_index_curation: false)
        end

        it 'does not check for alias info or add any delete ops' do
          expect(es_client).not_to receive(:indices)
          expect(indexer).not_to receive(:delete)

          indexer.process(issue_as_ref)

          expect(indexer.flush).to be_empty
        end
      end
    end

    context 'deleting an issue' do
      it 'removes the issue from the index' do
        ensure_elasticsearch_index!

        expect(issue_as_ref).to receive(:database_record).and_return(nil)

        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty

        refresh_index!

        expect(search(Issue, '*').size).to eq(0)
      end

      it 'succeeds even if the issue is not present' do
        expect(issue_as_ref).to receive(:database_record).and_return(nil)

        indexer.process(issue_as_ref)

        expect(indexer.flush).to be_empty

        refresh_index!

        expect(search(Issue, '*').size).to eq(0)
      end
    end
  end

  def ref(record)
    Gitlab::Elastic::DocumentReference.build(record)
  end

  def stub_es_client(indexer, client)
    allow(indexer).to receive(:client) { client }
  end

  def set_bulk_limit(indexer, bytes)
    allow(indexer).to receive(:bulk_limit_bytes) { bytes }
  end

  def search(klass, text)
    klass.__elasticsearch__.search(text)
  end

  def search_one(klass)
    results = search(klass, '*')

    expect(results.size).to eq(1)

    results.first._source
  end
end
