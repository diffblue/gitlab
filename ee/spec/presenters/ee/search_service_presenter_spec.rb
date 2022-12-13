# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchServicePresenter, feature_category: :global_search do
  describe '#advanced_search_enabled?' do
    let(:user) { build(:user) }

    subject(:presenter) { described_class.new(search_service, current_user: user) }

    context 'when Elasticsearch is enabled' do
      let(:search_service) { instance_double(SearchService, use_elasticsearch?: true) }

      it { is_expected.to be_advanced_search_enabled }
    end

    context 'when Elasticsearch is not enabled' do
      let(:search_service) { instance_double(SearchService, use_elasticsearch?: false) }

      it { is_expected.not_to be_advanced_search_enabled }
    end
  end
end
