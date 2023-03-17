# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::InstrumentationHelper do
  describe '.add_instrumentation_data', :request_store, feature_category: :global_search do
    let(:payload) { {} }

    subject { described_class.add_instrumentation_data(payload) }

    # We don't want to interact with Elasticsearch in GitLab FOSS so we test
    # this in ee/ only. The code exists in FOSS and won't do anything.
    context 'when Elasticsearch calls are made', :elastic do
      it 'adds Elasticsearch data' do
        ensure_elasticsearch_index!

        subject

        expect(payload[:elasticsearch_calls]).to be > 0
        expect(payload[:elasticsearch_duration_s]).to be > 0
        expect(payload[:elasticsearch_timed_out_count]).to be_kind_of(Integer)
      end
    end

    context 'when Zoekt calls are made', :zoekt do
      it 'adds Zoekt data' do
        search_results = Gitlab::Zoekt::SearchResults.new(nil, 'query')
        search_results.objects('blobs')

        subject

        expect(payload[:zoekt_calls]).to be > 0
        expect(payload[:zoekt_duration_s]).to be > 0
      end
    end
  end
end
