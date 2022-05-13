# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class SecurityDashboard < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_list.vue' do
              element :vulnerability
              element :vulnerability_report_checkbox_all
              element :false_positive_vulnerability
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/selection_summary.vue' do
              element :vulnerability_card_status_dropdown
              element :change_status_button
            end

            def has_vulnerability?(description:)
              has_element?(:vulnerability, vulnerability_description: description)
            end

            def has_false_positive_vulnerability?
              has_element?(:false_positive_vulnerability)
            end

            def click_vulnerability(description:)
              return false unless has_vulnerability?(description: description)

              click_element(:vulnerability, vulnerability_description: description)
            end

            def select_all_vulnerabilities
              check_element(:vulnerability_report_checkbox_all, true)
            end

            def change_bulk_state(status)
              click_element(:vulnerability_card_status_dropdown)
              click_element("item_status_#{status.downcase}")
              click_element(:change_status_button)
            end
          end
        end
      end
    end
  end
end
