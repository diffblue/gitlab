# frozen_string_literal: true

require 'spec_helper'

# We don't want to interact with Elasticsearch in GitLab FOSS so we test
# this in ee/ only. The code exists in FOSS and won't do anything.

RSpec.describe Peek::Views::Elasticsearch, :elastic, :request_store do
  before do
    allow(::Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    ensure_elasticsearch_index!
  end

  describe '#results' do
    let(:results) { described_class.new.results }
    let(:project) { create(:project, :repository) }
    let(:timeout) { '30s' }

    it 'includes performance details' do
      ::Gitlab::SafeRequestStore.clear!

      project.repository.__elasticsearch__.elastic_search_as_found_blob('hello world')

      expect(results[:calls]).to be > 0
      expect(results[:duration]).to be_kind_of(String)
      expect(results[:details].last[:method]).to eq('GET')
      expect(results[:details].last[:path]).to eq('gitlab-test/doc/_search')
      expect(results[:details].last[:params]).to eq({ routing: "project_#{project.id}", timeout: timeout })

      expect(results[:details].last[:request]).to eq("GET gitlab-test/doc/_search?routing=project_#{project.id}&timeout=#{timeout}")
    end
  end
end
