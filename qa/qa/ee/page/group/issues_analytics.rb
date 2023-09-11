# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class IssuesAnalytics < QA::Page::Base
          view 'ee/app/assets/javascripts/issues_analytics/components/issues_analytics.vue' do
            element :issues_analytics_graph
            element :issues_analytics_chart_wrapper
          end

          def graph
            wait_issues_analytics_graph_finish_loading do
              find_element(:issues_analytics_graph)
            end
          end

          private

          def wait_issues_analytics_graph_finish_loading
            within_element(:issues_analytics_chart_wrapper) do
              wait_until(reload: false, max_duration: 5, sleep_interval: 1) do
                finished_loading?
                yield
              end
            end
          end
        end
      end
    end
  end
end
