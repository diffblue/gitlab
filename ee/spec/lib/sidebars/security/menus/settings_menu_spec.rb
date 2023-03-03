# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Security::Menus::SettingsMenu, feature_category: :navigation do
  it_behaves_like 'Top-Level menu item',
    link: '/-/security/dashboard/settings',
    title: _('Settings'),
    icon: 'settings',
    active_route: 'security/dashboard#settings'
end
