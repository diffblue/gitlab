# frozen_string_literal: true

module QA
  module EE
    module Page
      module Insights
        class Show < QA::Page::Base
          view 'ee/app/assets/javascripts/insights/components/insights.vue' do
            element :insights_dashboard_dropdown
          end

          view 'ee/app/assets/javascripts/insights/components/insights_page.vue' do
            element :insights_charts
            element :insights_page
          end

          def wait_for_insight_charts_to_load
            has_element?(:insights_charts, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def select_insights_dashboard(title)
            click_element :insights_dashboard_dropdown
            within_insights_dropdown do
              has_text?(title)
              click_on title
            end

            wait_for_insight_charts_to_load
          end

          def has_insights_dashboard_title?(title)
            within_insights_page do
              has_text?(title)
            end
          end

          def within_insights_dropdown(&block)
            within_element :insights_dashboard_dropdown, &block
          end

          def within_insights_page(&block)
            within_element :insights_page, &block
          end
        end
      end
    end
  end
end
