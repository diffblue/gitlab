# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Entities::GeoSite, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let!(:geo_node) { create(:geo_node) }
  let(:entity) { described_class.new(geo_node, request: double) }
  let(:error) { 'Could not connect to Geo database' }

  subject { entity.as_json }

  before do
    stub_primary_node
  end

  describe '#web_edit_url' do
    it { expect(subject[:web_edit_url]).to eq Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_node) }
  end

  describe '#self' do
    it { expect(subject[:_links][:self]).to eq expose_url(api_v4_geo_sites_path(id: geo_node.id)) }
  end

  describe '#status' do
    it { expect(subject[:_links][:status]).to eq expose_url(api_v4_geo_sites_status_path(id: geo_node.id)) }
  end

  describe '#repair' do
    it { expect(subject[:_links][:repair]).to eq expose_url(api_v4_geo_sites_repair_path(id: geo_node.id)) }
  end

  describe '#current' do
    context 'when node is current' do
      before do
        allow(Gitlab.config.geo).to receive(:node_name).and_return geo_node.name
      end

      it { expect(subject[:current]).to eq true }
    end

    context 'when node is not current' do
      before do
        allow(Gitlab.config.geo).to receive(:node_name).and_return 'test name'
      end

      it { expect(subject[:current]).to eq false }
    end
  end
end
