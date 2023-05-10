# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elasticsearch::Model::Adapter::Multiple::Records, :elastic, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  describe '#records' do
    let(:user) { create(:user) }
    let(:search_options) { { options: { current_user: user, project_ids: :any } } }
    let(:records) { Elasticsearch::Model.search('*', [Issue, MergeRequest]).records.to_a }

    let!(:issue) { create(:issue) }
    let!(:merge_request) { create(:merge_request) }

    it 'returns results from both classes in different Elasticsearch indexes' do
      ensure_elasticsearch_index!

      expect(records).to match_array([issue, merge_request])
    end
  end
end
