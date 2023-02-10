# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class ContributionAnalytics < QA::Page::Base
          view 'ee/app/assets/javascripts/analytics/contribution_analytics/legacy_components/pushes_chart.vue' do
            element :push_content
          end

          # rubocop:disable Layout/LineLength
          view 'ee/app/assets/javascripts/analytics/contribution_analytics/legacy_components/merge_requests_chart.vue' do
            element :merge_request_content
          end
          # rubocop:enable Layout/LineLength

          view 'ee/app/assets/javascripts/analytics/contribution_analytics/legacy_components/issues_chart.vue' do
            element :issue_content
          end

          def has_push_element?(text)
            has_element? :push_content, text: text
          end

          def has_mr_element?(text)
            has_element? :merge_request_content, text: text
          end

          def has_issue_element?(text)
            has_element? :issue_content, text: text
          end
        end
      end
    end
  end
end
