# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::OperationsDashboardMenu, feature_category: :navigation do
  it_behaves_like 'Top-Level menu item',
    is_super_sidebar: false,
    access_check: :read_operations_dashboard,
    link: '/-/operations',
    title: _('Operations Dashboard'),
    icon: 'cloud-gear',
    active_route: 'operations#index'

  it_behaves_like 'Top-Level menu item',
    is_super_sidebar: true,
    access_check: :read_operations_dashboard,
    link: '/-/operations',
    title: _('Operations'),
    icon: 'cloud-gear',
    active_route: 'operations#index'
end
