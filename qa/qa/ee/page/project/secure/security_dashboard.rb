# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class SecurityDashboard < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_list.vue' do
              element :vulnerability
              element 'vulnerability-checkbox-all'
              element 'false-positive-vulnerability'
              element 'vulnerability-remediated-badge-content'
              element 'vulnerability-issue-created-badge-content'
              element 'vulnerability-status-content'
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/selection_summary.vue' do
              element 'status-listbox'
              element 'change-status-button'
              element 'dismissal-reason-listbox'
              element 'change-status-comment-textbox'
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_report_header.vue' do
              element 'export-vulnerabilities-button'
              element 'vulnerability-report-header'
            end

            def has_vulnerability?(description:)
              has_element?(:vulnerability, vulnerability_description: description)
            end

            def has_false_positive_vulnerability?
              has_element?('false-positive-vulnerability')
            end

            def click_vulnerability(description:)
              return false unless has_vulnerability?(description: description)

              click_element(:vulnerability, vulnerability_description: description)
              wait_for_requests
            end

            def select_all_vulnerabilities
              check_element('vulnerability-checkbox-all', true)
            end

            def select_single_vulnerability(vulnerability_name)
              click_element('vulnerability-status-content', status_description: vulnerability_name)
            end

            def change_state(status, dismissal_reason = "not_applicable")
              retry_until(max_attempts: 3, sleep_interval: 2, message: "Setting status and comment") do
                click_element('status-listbox', wait: 5)
                click_element(:"listbox-item-#{status}", wait: 5)
                has_element?('change-status-comment-textbox', wait: 2)
              end

              if status.include?("dismissed")
                click_element('dismissal-reason-listbox')
                select_dismissal_reason(dismissal_reason)
              end

              fill_element('change-status-comment-textbox', "E2E Test")
              click_element('change-status-button')
            end

            def select_dismissal_reason(reason)
              click_element(:"listbox-item-#{reason}")
            end

            def has_remediated_badge?(vulnerability_name)
              has_element?('vulnerability-remediated-badge-content', activity_description: vulnerability_name)
            end

            def has_issue_created_icon?(vulnerability_name)
              has_element?('vulnerability-issue-created-badge-content', badge_description: vulnerability_name)
            end

            def export_vulnerabilities_to_csv
              click_element('export-vulnerabilities-button')
            end

            def wait_for_vuln_report_to_load
              wait_until(max_duration: 20, sleep_interval: 2, message: "Vulnerability report not loaded yet") do
                has_element?('vulnerability-report-header')
              end
              wait_for_requests
            end
          end
        end
      end
    end
  end
end
