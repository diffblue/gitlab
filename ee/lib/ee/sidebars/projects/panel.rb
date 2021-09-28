# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Panel
        extend ::Gitlab::Utils::Override

        override :configure_menus
        def configure_menus
          super

          if jira_menu.render?
            replace_menu(::Sidebars::Projects::Menus::ExternalIssueTrackerMenu, jira_menu)
          end
        end

        private

        def jira_menu
          @jira_menu ||= ::Sidebars::Projects::Menus::JiraMenu.new(context)
        end
      end
    end
  end
end
