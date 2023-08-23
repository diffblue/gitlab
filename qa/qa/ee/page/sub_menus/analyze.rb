# frozen_string_literal: true

module QA
  module EE
    module Page
      module SubMenus
        module Analyze
          def go_to_value_stream_analytics
            open_analyze_submenu('Value stream analytics')
          end

          def go_to_ci_cd_analytics
            open_analyze_submenu('CI/CD analytics')
          end

          def go_to_repository_analytics
            open_analyze_submenu('Repository analytics')
          end

          def go_to_issue_analytics
            open_analyze_submenu('Issue analytics')
          end

          def go_to_insights
            open_analyze_submenu('Insights')
          end

          private

          def open_analyze_submenu(sub_menu)
            open_submenu('Analyze', sub_menu)
          end
        end
      end
    end
  end
end
