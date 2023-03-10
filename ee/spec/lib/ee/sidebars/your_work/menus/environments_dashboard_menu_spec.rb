# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::EnvironmentsDashboardMenu, feature_category: :navigation do
  it_behaves_like 'top-level menu item',
    is_super_sidebar: false,
    link: '/-/operations/environments',
    title: _('Environments Dashboard'),
    icon: 'environment',
    active_route: { path: 'operations#environments' }

  it_behaves_like 'top-level menu item',
    is_super_sidebar: true,
    link: '/-/operations/environments',
    title: _('Environments'),
    icon: 'environment',
    active_route: { path: 'operations#environments' }

  it_behaves_like 'top-level menu item with license feature guard',
    access_check: :read_operations_dashboard

  it_behaves_like 'menu without sub menu items'
end
