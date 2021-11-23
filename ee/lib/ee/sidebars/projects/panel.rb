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
        end
      end
    end
  end
end
