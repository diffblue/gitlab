# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AdvancedSearch::LimitedIndexingMetric,
  feature_category: :global_search do
  before do
    stub_licensed_features(elastic_search: true)
  end

  describe '#value' do
    context 'when elasticsearch_limit_indexing is enabled' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
      end

      it_behaves_like 'a correct instrumented metric value', { data_source: 'system', time_frame: 'none' } do
        let(:expected_value) { true }
      end
    end

    context 'when elasticsearch_limit_indexing is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: false)
      end

      it_behaves_like 'a correct instrumented metric value', { data_source: 'system', time_frame: 'none' } do
        let(:expected_value) { false }
      end
    end
  end

  describe '#available?' do
    using RSpec::Parameterized::TableSyntax

    where(:license, :indexing, :expected) do
      true | true | true
      true | false | false
      false | false | false
      false | true | false
    end

    with_them do
      before do
        stub_ee_application_setting(elasticsearch_indexing: indexing)
        stub_licensed_features(elastic_search: license)
      end

      subject(:available) { described_class.new(time_frame: 'none', options: { data_source: 'system' }).available? }

      it { is_expected.to eq(expected) }
    end
  end
end
