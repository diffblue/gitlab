# frozen_string_literal: true

require 'spec_helper'

# We don't want to interact with Elasticsearch in GitLab FOSS so we test
# this in ee/ only. The code exists in FOSS and won't do anything.

RSpec.describe ::Gitlab::Instrumentation::ElasticsearchTransport, :elastic, :request_store, feature_category: :global_search do
  describe '.increment_request_count' do
    it 'increases the request count by 1' do
      expect { described_class.increment_request_count }.to change(described_class, :get_request_count).by(1)
    end
  end

  describe '.increment_timed_out_count' do
    it 'increases the timed out count by 1' do
      expect { described_class.increment_timed_out_count }.to change(described_class, :get_timed_out_count).by(1)
    end
  end

  describe '.add_duration' do
    it 'does not lose precision while adding' do
      ::Gitlab::SafeRequestStore.clear!

      precision = 1.0 / (10**::Gitlab::InstrumentationHelper::DURATION_PRECISION)
      2.times { described_class.add_duration(0.4 * precision) }

      # 2 * 0.4 should be 0.8 and get rounded to 1
      expect(described_class.query_time).to eq(1 * precision)
    end
  end

  describe '.add_call_details' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    end

    it 'parses and tracks the call details', :use_clean_rails_memory_store_caching do
      create(:merge_request, title: "cache warming MR") # Warm cache for checking migrations are finished
      ensure_elasticsearch_index!

      ::Gitlab::SafeRequestStore.clear!

      create(:merge_request, title: "new MR")
      ensure_elasticsearch_index!

      requests = described_class.detail_store
      expect(requests).to include(a_hash_including(method: "POST", path: "_bulk"))
    end
  end
end

RSpec.describe ::Gitlab::Instrumentation::ElasticsearchTransportInterceptor, :elastic, :request_store, feature_category: :global_search do
  let(:elasticsearch_url) { Gitlab::CurrentSettings.elasticsearch_url[0] }

  before do
    allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  it 'tracks any requests via the Elasticsearch client' do
    ensure_elasticsearch_index!

    expect(::Gitlab::Instrumentation::ElasticsearchTransport.get_request_count).to be > 0
    expect(::Gitlab::Instrumentation::ElasticsearchTransport.query_time).to be > 0
    expect(::Gitlab::Instrumentation::ElasticsearchTransport.detail_store).not_to be_empty
  end

  it 'adds the labkit correlation id as X-Opaque-Id to all requests' do
    allow(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('new-correlation-id')

    Repository.__elasticsearch__.client
      .perform_request(:get, '/')

    expect(a_request(:get, /#{elasticsearch_url}/)
      .with(headers: { 'X-Opaque-Id' => 'new-correlation-id' })).to have_been_made
  end

  it 'does not override the X-Opaque-Id if it is already present' do
    allow(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return('new-correlation-id')

    Repository.__elasticsearch__.client
      .perform_request(:get, '/', {}, nil, { 'X-Opaque-Id': 'original-opaque-id' })

    expect(a_request(:get, /#{elasticsearch_url}/)
      .with(headers: { 'X-Opaque-Id' => 'original-opaque-id' })).to have_been_made
  end

  context 'when the response indicates a server side timeout' do
    it 'increments timeouts' do
      stub_request(:any, /#{elasticsearch_url}/).to_return(body: +'{"timed_out": true}', status: 200, headers: { 'Content-Type' => 'application/json' })

      Repository.__elasticsearch__.client.perform_request(:get, '/')

      expect(::Gitlab::Instrumentation::ElasticsearchTransport.get_timed_out_count).to eq(1)
    end
  end

  context 'when the response does not indicate a server side timeout' do
    it 'does not increment timeouts' do
      stub_request(:any, /#{elasticsearch_url}/).to_return(body: +'{"timed_out": false}', status: 200, headers: { 'Content-Type' => 'application/json' })

      Repository.__elasticsearch__.client.perform_request(:get, '/')

      expect(::Gitlab::Instrumentation::ElasticsearchTransport.get_timed_out_count).to eq(0)
    end
  end

  context 'when the server returns a blank response body' do
    it 'does not error' do
      stub_request(:any, /#{elasticsearch_url}/).to_return(body: +'', status: 200)

      Repository.__elasticsearch__.client.perform_request(:get, '/')
    end
  end

  context 'when the request raises some error' do
    it 'does not raise a different error in ensure' do
      stub_request(:any, /#{elasticsearch_url}/).to_return(body: +'', status: 500)

      expect { Repository.__elasticsearch__.client.perform_request(:get, '/') }
        .to raise_error(::Elasticsearch::Transport::Transport::Errors::InternalServerError)
    end
  end
end
