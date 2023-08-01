# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class Show < QA::Page::Base
            include Page::Component::SecureReport

            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/security_dashboard_table.vue' do
              element 'security-report-content', required: true
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_list.vue' do
              element 'false-positive-vulnerability'
            end

            def has_false_positive_vulnerability?
              has_element?('false-positive-vulnerability')
            end
          end
        end
      end
    end
  end
end
