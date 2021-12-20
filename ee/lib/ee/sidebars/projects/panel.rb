# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          insert_menu_before(::Sidebars::Projects::Menus::ProjectInformationMenu,
                             ::Sidebars::Projects::Menus::TrialExperimentMenu.new(context))

          if ::Sidebars::Projects::Menus::IssuesMenu.new(context).show_jira_menu_items?
            remove_menu(::Sidebars::Projects::Menus::ExternalIssueTrackerMenu)
          end

          add_billing_sidebar_menu
        end

        private

        def add_billing_sidebar_menu
          experiment(:billing_in_side_nav, actor: context.current_user, namespace: context.project.namespace.root_ancestor, sticky_to: context.current_user) do |e|
            e.control {}
            e.candidate do
              insert_menu_after(::Sidebars::Projects::Menus::SettingsMenu, ::Sidebars::Projects::Menus::BillingMenu.new(context))
            end
          end
        end
      end
    end
  end
end
