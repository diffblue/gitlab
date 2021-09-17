# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210722112600_add_upvotes_to_merge_requests.rb')

RSpec.describe AddUpvotesToMergeRequests, :elastic, :sidekiq_inline do
  let(:version) { 20210722112600 }
  let(:migration) { described_class.new(version) }
  let(:merge_requests) { create_list(:merge_request, 3, :unique_branches) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    # ensure merge requests are indexed
    merge_requests

    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.throttle_delay).to eq(3.minutes)
      expect(migration.batch_size).to eq(5000)
    end
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      it 'does not modify data' do
        expect(::Elastic::ProcessInitialBookkeepingService).not_to receive(:track!)

        subject
      end
    end

    context 'migration process' do
      before do
        remove_upvotes_from_merge_requests(merge_requests)
      end

      it 'updates all merge request documents' do
        # track calls are batched in groups of 100
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).once do |*tracked_refs|
          expect(tracked_refs.count).to eq(3)
        end

        subject
      end

      it 'only updates merge request documents missing upvotes', :aggregate_failures do
        merge_request = merge_requests.first
        add_upvotes_for_merge_requests(merge_requests[1..-1])

        expected = [Gitlab::Elastic::DocumentReference.new(MergeRequest, merge_request.id, merge_request.es_id, merge_request.es_parent)]
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*expected).once

        subject
      end

      it 'processes in batches', :aggregate_failures do
        allow(migration).to receive(:batch_size).and_return(2)
        stub_const('::Elastic::MigrationBackfillHelper::UPDATE_BATCH_SIZE', 1)

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).exactly(3).times.and_call_original

        # cannot use subject in spec because it is memoized
        migration.migrate

        ensure_elasticsearch_index!

        migration.migrate
      end
    end
  end

  describe '.completed?' do
    context 'when documents are missing upvotes' do
      before do
        remove_upvotes_from_merge_requests(merge_requests)
      end

      specify { expect(migration).not_to be_completed }
    end

    context 'when no documents are missing upvotes' do
      specify { expect(migration).to be_completed }
    end
  end

  private

  def add_upvotes_for_merge_requests(merge_requests)
    script =  {
      source: "ctx._source['upvotes'] = params.upvotes;",
      lang: "painless",
      params: {
        upvotes: 0
      }
    }

    update_by_query(merge_requests, script)
  end

  def remove_upvotes_from_merge_requests(merge_requests)
    script =  {
      source: "ctx._source.remove('upvotes')"
    }

    update_by_query(merge_requests, script)
  end

  def update_by_query(merge_requests, script)
    merge_request_ids = merge_requests.map(&:id)

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
                                     }
                                   ]
                                 }
                               }
                             }
                           })
  end
end
