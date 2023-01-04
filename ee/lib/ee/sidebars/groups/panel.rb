# frozen_string_literal: true

module EE
  module Sidebars
    module Groups
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          insert_menu_before(::Sidebars::Groups::Menus::GroupInformationMenu, ::Sidebars::Groups::Menus::TrialWidgetMenu.new(context))
          insert_menu_after(::Sidebars::Groups::Menus::GroupInformationMenu, ::Sidebars::Groups::Menus::EpicsMenu.new(context))
          insert_menu_after(::Sidebars::Groups::Menus::MergeRequestsMenu, ::Sidebars::Groups::Menus::SecurityComplianceMenu.new(context))
          insert_menu_after(::Sidebars::Groups::Menus::PackagesRegistriesMenu, ::Sidebars::Groups::Menus::AnalyticsMenu.new(context))
          insert_menu_after(::Sidebars::Groups::Menus::AnalyticsMenu, ::Sidebars::Groups::Menus::WikiMenu.new(context))
          insert_menu_after(::Sidebars::Groups::Menus::SettingsMenu, ::Sidebars::Groups::Menus::AdministrationMenu.new(context))
        end
      end
    end
  end
end
