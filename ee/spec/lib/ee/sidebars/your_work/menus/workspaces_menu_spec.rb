# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::WorkspacesMenu, feature_category: :remote_development do
  it_behaves_like 'top-level menu item',
    is_super_sidebar: false,
    link: '/-/remote_development/workspaces',
    title: 'Workspaces',
    icon: 'cloud-terminal',
    active_route: { path: 'remote_development/workspaces#index' }

  it_behaves_like 'top-level menu item',
    is_super_sidebar: true,
    link: '/-/remote_development/workspaces',
    title: 'Workspaces',
    icon: 'cloud-terminal',
    active_route: { path: 'remote_development/workspaces#index' }

  it_behaves_like 'top-level menu item with license feature guard',
    access_check: :read_workspace

  it_behaves_like 'menu without sub menu items'
end
