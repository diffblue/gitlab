# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::OperationsDashboardMenu, feature_category: :navigation do
  it_behaves_like 'top-level menu item',
    is_super_sidebar: false,
    link: '/-/operations',
    title: _('Operations Dashboard'),
    icon: 'cloud-gear',
    active_route: { path: 'operations#index' }

  it_behaves_like 'top-level menu item',
    is_super_sidebar: true,
    link: '/-/operations',
    title: _('Operations'),
    icon: 'cloud-gear',
    active_route: { path: 'operations#index' }

  it_behaves_like 'top-level menu item with license feature guard',
    access_check: :read_operations_dashboard

  it_behaves_like 'menu without sub menu items'
end
