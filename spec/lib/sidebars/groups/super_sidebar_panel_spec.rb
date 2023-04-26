# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Groups::SuperSidebarPanel, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_owner(user) } }

  let(:context) do
    Sidebars::Groups::Context.new(
      current_user: user,
      container: group,
      is_super_sidebar: true,
      # Turn features off that do not add/remove menu items
      show_promotions: false,
      show_discover_group_security: false
    )
  end

  subject { described_class.new(context) }

  # We want to enable _all_ possible menu items for these specs
  before do
    # Give the user access to everything and enable every feature
    allow(Ability).to receive(:allowed?).and_return(true)
    allow(group).to receive(:licensed_feature_available?).and_return(true)
    # Needed to show Container Registry items
    allow(::Gitlab.config.registry).to receive(:enabled).and_return(true)
    # Needed to show Billing
    allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
    # Needed to show LDAP Group Sync
    allow(::Gitlab::Auth::Ldap::Config).to receive(:group_sync_enabled?).and_return(true)
    # Needed for Domain Verification entry
    allow(group).to receive(:domain_verification_available?).and_return(true)
  end

  it 'implements #super_sidebar_context_header' do
    expect(subject.super_sidebar_context_header).to eq(
      {
        title: group.name,
        avatar: group.avatar_url,
        id: group.id
      })
  end

  describe '#renderable_menus' do
    let(:category_menu) do
      [
        Sidebars::StaticMenu,
        Sidebars::Groups::SuperSidebarMenus::ManageMenu,
        Sidebars::Groups::SuperSidebarMenus::PlanMenu,
        Sidebars::Groups::SuperSidebarMenus::BuildMenu,
        Sidebars::Groups::SuperSidebarMenus::SecureMenu,
        Sidebars::Groups::SuperSidebarMenus::OperationsMenu,
        Sidebars::Groups::SuperSidebarMenus::MonitorMenu,
        Sidebars::Groups::SuperSidebarMenus::AnalyzeMenu,
        Sidebars::UncategorizedMenu,
        Sidebars::Groups::Menus::SettingsMenu
      ]
    end

    it "is exposed as a renderable menu" do
      expect(subject.instance_variable_get(:@menus).map(&:class)).to eq(category_menu)
    end
  end

  it_behaves_like 'a panel with uniquely identifiable menu items'
  it_behaves_like 'a panel with all menu_items categorized'
  it_behaves_like 'a panel without placeholders in EE'
end
