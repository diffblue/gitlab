# frozen_string_literal: true

require 'spec_helper'

# We don't want to interact with Zoekt in GitLab FOSS so we test
# this in ee/ only. The code exists in FOSS and won't do anything.

RSpec.describe Peek::Views::Zoekt, :zoekt, :request_store, feature_category: :global_search do
  before do
    ::Gitlab::Instrumentation::Zoekt.detail_store # Create store in redis
    allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
  end

  describe '#results' do
    let_it_be(:project) { create(:project, :repository) }

    let(:results) { described_class.new.results }
    let(:timeout) { '30s' }

    it 'includes performance details' do
      ::Gitlab::SafeRequestStore.clear!

      search_results = Gitlab::Zoekt::SearchResults.new(nil, 'query', [project.id])
      search_results.objects('blobs')

      expect(results[:calls]).to be > 0
      expect(results[:duration]).to be_kind_of(String)
      expect(results[:details].last[:method]).to eq('POST')
      expect(results[:details].last[:path]).to eq('/api/search')
      expect(results[:details].last[:request]).to eq("POST /api/search?")
    end
  end
end
