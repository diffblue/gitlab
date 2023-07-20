# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class SecurityDashboard < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_list.vue' do
              element :vulnerability
              element :vulnerability_checkbox_all
              element :false_positive_vulnerability
              element :vulnerability_remediated_badge_content
              element :vulnerability_issue_created_badge_content
              element :vulnerability_status_content
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/selection_summary.vue' do
              element :status_listbox
              element :change_status_button
              element :dismissal_reason_listbox
              element :change_status_comment_textbox
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_report_header.vue' do
              element :export_vulnerabilities_button
              element :vulnerability_report_header
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
              wait_for_requests
            end

            def select_all_vulnerabilities
              check_element(:vulnerability_checkbox_all, true)
            end

            def select_single_vulnerability(vulnerability_name)
              click_element(:vulnerability_status_content, status_description: vulnerability_name)
            end

            def change_state(status, dismissal_reason = "not_applicable")
              retry_until(max_attempts: 3, sleep_interval: 2, message: "Setting status and comment") do
                click_element(:status_listbox, wait: 5)
                click_element(:"listbox-item-#{status}", wait: 5)
                has_element?(:change_status_comment_textbox, wait: 2)
              end

              if status.include?("dismissed")
                click_element(:dismissal_reason_listbox)
                select_dismissal_reason(dismissal_reason)
              end

              fill_element(:change_status_comment_textbox, "E2E Test")
              click_element(:change_status_button)
            end

            def select_dismissal_reason(reason)
              click_element(:"listbox-item-#{reason}")
            end

            def has_remediated_badge?(vulnerability_name)
              has_element?(:vulnerability_remediated_badge_content, activity_description: vulnerability_name)
            end

            def has_issue_created_icon?(vulnerability_name)
              has_element?(:vulnerability_issue_created_badge_content, badge_description: vulnerability_name)
            end

            def export_vulnerabilities_to_csv
              click_element(:export_vulnerabilities_button)
            end

            def wait_for_vuln_report_to_load
              wait_until(max_duration: 20, sleep_interval: 2, message: "Vulnerability report not loaded yet") do
                has_element?(:vulnerability_report_header)
              end
              wait_for_requests
            end
          end
        end
      end
    end
  end
end
