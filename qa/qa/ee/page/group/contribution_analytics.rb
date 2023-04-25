# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class ContributionAnalytics < QA::Page::Base
          view 'ee/app/assets/javascripts/analytics/contribution_analytics/components/pushes_chart.vue' do
            element :push_content
          end

          # rubocop:disable Layout/LineLength
          view 'ee/app/assets/javascripts/analytics/contribution_analytics/components/merge_requests_chart.vue' do
            element :merge_request_content
          end
          # rubocop:enable Layout/LineLength

          view 'ee/app/assets/javascripts/analytics/contribution_analytics/components/issues_chart.vue' do
            element :issue_content
          end

          def push_analytics_content
            find_element(:push_content)
          end

          def mr_analytics_content
            find_element(:merge_request_content)
          end

          def issue_analytics_content
            find_element(:issue_content)
          end
        end
      end
    end
  end
end
