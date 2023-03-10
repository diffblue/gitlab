# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::JsonRequest, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let(:geo_node) { create(:geo_node) }
  let(:request) { described_class.new }

  before do
    stub_current_geo_node(geo_node)
  end

  describe '#headers' do
    it 'contains the JSON request headers' do
      expect(request.headers).to include('Content-Type' => 'application/json')
    end
  end
end
