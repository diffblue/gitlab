# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_read_only_banner' do
  include EE::GeoHelpers

  let_it_be(:geo_primary) { create(:geo_node, :primary) }
  let_it_be(:geo_secondary) { create(:geo_node) }

  context 'On a Geo primary node' do
    before do
      stub_current_geo_node(geo_primary)
    end

    it 'do not includes button to visit primary node' do
      render

      expect(rendered).not_to have_link 'Go to the primary site'
    end
  end

  context 'On a Geo secondary node' do
    before do
      stub_current_geo_node(geo_secondary)
    end

    it 'includes button to visit primary node' do
      render

      expect(rendered).to have_link 'Go to the primary site', href: geo_primary.url
    end
  end
end
