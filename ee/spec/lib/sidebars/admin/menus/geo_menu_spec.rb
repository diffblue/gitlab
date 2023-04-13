# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Admin::Menus::GeoMenu, feature_category: :navigation do
  it_behaves_like 'Admin menu',
    link: '/admin/geo/sites',
    title: s_('Admin|Geo'),
    icon: 'location-dot'

  it_behaves_like 'Admin menu with sub menus'
end
