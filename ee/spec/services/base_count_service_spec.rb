# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BaseCountService, feature_category: :shared do
  include ::EE::GeoHelpers

  describe '#update_cache_for_key' do
    let(:key) { %w{a cache key} }

    it 'calls Gitlab::Cache.delete_on_geo_secondaries' do
      expect(::Gitlab::Cache).to receive(:delete_on_geo_secondaries).with(key)

      described_class.new.update_cache_for_key(key) { 123 }
    end
  end
end
