# frozen_string_literal: true

module Sidebars
  module Security
    class Panel < ::Sidebars::Panel
      override :configure_menus
      def configure_menus
        add_menu(Sidebars::Security::Menus::SecurityDashboardMenu.new(context))
        add_menu(Sidebars::Security::Menus::VulnerabilityReportMenu.new(context))
        add_menu(Sidebars::Security::Menus::SettingsMenu.new(context))
      end

      override :aria_label
      def aria_label
        _("Security navigation")
      end

      override :render_raw_scope_menu_partial
      def render_raw_scope_menu_partial
        "shared/nav/security_scope_header"
      end

      override :super_sidebar_context_header
      def super_sidebar_context_header
        @super_sidebar_context_header ||= {
          title: _('Security'),
          avatar: ActionController::Base.helpers.image_path('logo.svg')
        }
      end
    end
  end
end

Sidebars::Security::Panel.prepend_mod_with('Sidebars::Security::Panel')
