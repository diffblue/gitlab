# frozen_string_literal: true

module EE
  module Sidebars
    module Projects
      module Menus
        module ZentaoMenu
          extend ::Gitlab::Utils::Override

          override :link
          def link
            return super unless feature_available?

            project_integrations_zentao_issues_path(context.project)
          end

          override :add_items
          def add_items
            add_item(issue_list_menu_item) if feature_available?
            super
          end

          private

          def feature_available?
            ::Integrations::Zentao.issues_license_available?(context.project)
          end

          def issue_list_menu_item
            ::Sidebars::MenuItem.new(
              title: s_('ZentaoIntegration|Issue list'),
              link: project_integrations_zentao_issues_path(context.project),
              active_routes: { controller: 'projects/integrations/zentao/issues' },
              item_id: :issue_list
            )
          end
        end
      end
    end
  end
end
