# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210421140400_add_new_data_to_merge_requests_documents.rb')

RSpec.describe AddNewDataToMergeRequestsDocuments, :elastic, :sidekiq_inline do
  let(:version) { 20210421140400 }
  let(:migration) { described_class.new(version) }
  let(:merge_requests) { create_list(:merge_request, 3) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to :add_new_data_to_merge_requests_documents, including: false

    # ensure merge_requests are indexed
    merge_requests

    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.throttle_delay).to eq(3.minutes)
    end
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      before do
        add_visibility_level_for_merge_requests(merge_requests)
      end

      it 'does not modify data', :aggregate_failures do
        expect(::Elastic::ProcessInitialBookkeepingService).not_to receive(:track!)

        subject
      end
    end

    context 'migration process' do
      before do
        remove_visibility_level_for_merge_requests(merge_requests)
      end

      it 'updates all merge_request documents' do
        # track calls are batched in groups of 100
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).once do |*tracked_refs|
          expect(tracked_refs.count).to eq(3)
        end

        subject
      end

      it 'only updates merge_request documents missing visibility_level', :aggregate_failures do
        merge_request = merge_requests.first
        add_visibility_level_for_merge_requests(merge_requests[1..])

        expected = [Gitlab::Elastic::DocumentReference.new(MergeRequest, merge_request.id, merge_request.es_id, merge_request.es_parent)]
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*expected).once

        subject
      end

      it 'processes in batches', :aggregate_failures do
        stub_const("#{described_class}::QUERY_BATCH_SIZE", 2)
        stub_const("#{described_class}::UPDATE_BATCH_SIZE", 1)

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).exactly(3).times.and_call_original

        # cannot use subject in spec because it is memoized
        migration.migrate

        ensure_elasticsearch_index!

        migration.migrate
      end
    end
  end

  describe '.completed?' do
    subject { migration.completed? }

    context 'when documents are missing visibility_level' do
      before do
        remove_visibility_level_for_merge_requests(merge_requests)
      end

      it { is_expected.to be_falsey }
    end

    context 'when no documents are missing visibility_level' do
      before do
        add_visibility_level_for_merge_requests(merge_requests)
      end

      it { is_expected.to be_truthy }
    end
  end

  private

  def add_visibility_level_for_merge_requests(merge_requests)
    script =  {
      source: "ctx._source['visibility_level'] = params.visibility_level;",
      lang: "painless",
      params: {
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }
    }

    update_by_query(merge_requests, script)
  end

  def remove_visibility_level_for_merge_requests(merge_requests)
    script =  {
      source: "ctx._source.remove('visibility_level')"
    }

    update_by_query(merge_requests, script)
  end

  def update_by_query(merge_requests, script)
    merge_request_ids = merge_requests.map { |i| i.id }

    client = MergeRequest.__elasticsearch__.client
    client.update_by_query({
      index: MergeRequest.__elasticsearch__.index_name,
      wait_for_completion: true, # run synchronously
      refresh: true, # make operation visible to search
      body: {
        script: script,
        query: {
          bool: {
            must: [
              {
                terms: {
                  id: merge_request_ids
                }
              },
              {
                term: {
                  type: {
                    value: 'merge_request'
                  }
                }
              }
            ]
          }
        }
      }
    })
  end
end
