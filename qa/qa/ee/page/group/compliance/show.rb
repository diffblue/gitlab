# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Compliance
          class Show < QA::Page::Base
            view 'ee/app/assets/javascripts/compliance_dashboard/components/violations_report/report.vue' do
              element :violation_severity_content
              element :violation_reason_content
            end

            def has_violation?(reason, merge_request_title)
              has_element?(:violation_reason_content, text: reason, description: merge_request_title)
            end

            def violation_severity(merge_request_title)
              find_element(:violation_severity_content, description: merge_request_title).text
            end
          end
        end
      end
    end
  end
end
