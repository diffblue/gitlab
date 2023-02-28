# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Security::Menus::SecurityDashboardMenu, feature_category: :navigation do
  it_behaves_like 'Top-Level menu item',
    link: '/-/security/dashboard',
    title: _('Security Dashboard'),
    icon: 'dashboard',
    active_route: 'security/dashboard#show'
end
