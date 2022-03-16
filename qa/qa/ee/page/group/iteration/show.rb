# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Iteration
          class Show < QA::Page::Base
            view 'ee/app/assets/javascripts/iterations/components/iteration_report_issues.vue' do
              element :iteration_issues_container, required: true
              element :iteration_issue_link
            end

            view 'ee/app/assets/javascripts/burndown_chart/components/burndown_chart.vue' do
              element :burndown_chart
            end

            view 'ee/app/assets/javascripts/burndown_chart/components/burnup_chart.vue' do
              element :burnup_chart
            end

            def has_burndown_chart?
              has_element?(:burndown_chart)
            end

            def has_burnup_chart?
              has_element?(:burnup_chart)
            end

            def has_issue?(issue)
              within_element(:iteration_issues_container) do
                has_element?(:iteration_issue_link, issue_title: issue.title)
              end
            end

            def has_no_issue?(issue)
              within_element(:iteration_issues_container) do
                has_no_element?(:iteration_issue_link, issue_title: issue.title)
              end
            end
          end
        end
      end
    end
  end
end
