# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          unless context.is_super_sidebar
            insert_menu_before(
              ::Sidebars::Projects::Menus::ProjectInformationMenu,
              ::Sidebars::Projects::Menus::TrialWidgetMenu.new(context)
            )
          end

          insert_menu_after(
            ::Sidebars::Projects::Menus::ProjectInformationMenu,
            ::Sidebars::Projects::Menus::LearnGitlabMenu.new(context)
          )

          if ::Sidebars::Projects::Menus::IssuesMenu.new(context).show_jira_menu_items?
            remove_menu(::Sidebars::Projects::Menus::ExternalIssueTrackerMenu)
          end

          if ::Sidebars::Projects::Menus::IssuesMenu.new(context).show_zentao_menu_items?
            remove_menu(::Sidebars::Projects::Menus::ZentaoMenu)
          end
        end
      end
    end
  end
end
