# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Router::Rails, feature_category: :portfolio_management do
  it 'matches epic realtime_changes endpoint' do
    result = described_class.match(
      double(path_info: '/groups/my-group/and-subgroup/-/epics/1/realtime_changes')
    )

    expect(result).to be_present
    expect(result.name).to eq 'epic_realtime_changes'
  end

  it 'does not match invalid epic realtime_changes endpoint' do
    result = described_class.match(
      double(path_info: '/groups/my-group/-/and-subgroup/-/epics/1/realtime_changes')
    )

    expect(result).to be_blank
  end

  it 'has a valid feature category for every route', :aggregate_failures do
    feature_categories = Gitlab::FeatureCategories.default.categories

    described_class.ee_routes.each do |route|
      expect(feature_categories).to include(route.feature_category), "#{route.name} has a category of #{route.feature_category}, which is not valid"
    end
  end

  describe '.cache_key' do
    it 'returns a cache key' do
      request = double(path: '/path/to/resource')

      described_class.ee_routes.each do |route|
        expect(route.cache_key(request)).to eq '/path/to/resource'
      end
    end
  end
end
