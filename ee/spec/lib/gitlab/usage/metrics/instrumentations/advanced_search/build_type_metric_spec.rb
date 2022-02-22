# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AdvancedSearch::BuildTypeMetric do
  let(:mock_es_helper) { instance_double(Gitlab::Elastic::Helper, server_info: { build_type: 'docker' }) }

  before do
    allow(Gitlab::Elastic::Helper).to receive(:default).and_return(mock_es_helper)
  end

  it_behaves_like 'a correct instrumented metric value', { data_source: 'system' } do
    before do
      expect(mock_es_helper).not_to receive(:server_info)
    end

    let(:expected_value) { 'NA' }
  end

  context 'elasticsearch_indexing is enabled' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    it_behaves_like 'a correct instrumented metric value', { data_source: 'system' } do
      let(:expected_value) { 'docker' }
    end
  end
end
