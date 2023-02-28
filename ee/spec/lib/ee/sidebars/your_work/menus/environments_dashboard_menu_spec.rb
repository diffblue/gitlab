# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::EnvironmentsDashboardMenu, feature_category: :navigation do
  it_behaves_like 'Top-Level menu item',
    is_super_sidebar: false,
    access_check: :read_operations_dashboard,
    link: '/-/operations/environments',
    title: _('Environments Dashboard'),
    icon: 'environment',
    active_route: 'operations#environments'

  it_behaves_like 'Top-Level menu item',
    is_super_sidebar: true,
    access_check: :read_operations_dashboard,
    link: '/-/operations/environments',
    title: _('Environments'),
    icon: 'environment',
    active_route: 'operations#environments'
end
