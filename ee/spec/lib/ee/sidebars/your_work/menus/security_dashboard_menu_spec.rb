# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::YourWork::Menus::SecurityDashboardMenu, feature_category: :navigation do
  it_behaves_like 'top-level menu item',
    is_super_sidebar: false,
    link: '/-/security/dashboard',
    title: _('Security'),
    icon: 'shield',
    active_route: { controller: 'security/application' }

  it_behaves_like 'top-level menu item',
    is_super_sidebar: true,
    link: '/-/security/dashboard',
    title: _('Security'),
    icon: 'shield',
    active_route: { controller: 'security/application' }

  it_behaves_like 'top-level menu item with context based feature guard',
    guard: :show_security_dashboard

  it_behaves_like 'top-level menu item with sub menu items' do
    let(:sub_menu) do
      [
        {
          active_routes: { path: "security/dashboard#show" },
          item_id: :security_dashboard,
          link: "/-/security/dashboard",
          title: _("Security dashboard")
        },
        {
          active_routes: { path: "security/vulnerabilities#index" },
          item_id: :vulnerability_report,
          link: "/-/security/vulnerabilities",
          title: _("Vulnerability report")
        },
        {
          active_routes: { path: "security/dashboard#settings" },
          item_id: :security_settings,
          link: "/-/security/dashboard/settings",
          title: _("Settings")
        }
      ]
    end
  end
end
