# frozen_string_literal: true

module QA
  module EE
    module Page
      module MergeRequest
        module Show
          extend QA::Page::PageConcern

          ApprovalConditionsError = Class.new(RuntimeError)

          def self.prepended(base)
            super

            base.class_eval do
              prepend Page::Component::LicenseManagement

              view 'ee/app/views/projects/merge_requests/_code_owner_approval_rules.html.haml' do
                element :approver_content
                element :approver_list_content
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue' do
                element :vulnerability_report_grouped
                element :sast_scan_report
                element :dependency_scan_report
                element :container_scan_report
                element :dast_scan_report
                element :coverage_fuzzing_report
                element :api_fuzzing_report
              end

              view 'app/assets/javascripts/ci/reports/components/report_section.vue' do
                element :expand_report_button
              end

              view 'app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals.vue' do
                element :approve_button
              end

              view 'app/assets/javascripts/vue_merge_request_widget/components/approvals/approvals_summary.vue' do
                element :approvals_summary_content
              end

              view 'ee/app/assets/javascripts/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue' do
                element :merge_immediately_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/modal.vue' do
                element :vulnerability_modal_content
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/event_item.vue' do
                element :event_item_content
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/modal_footer.vue' do
                element :resolve_split_button
                element :create_issue_button
                element :cancel_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismiss_button.vue' do
                element :dismiss_with_comment_button
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue' do
                element :dismiss_comment_field
              end

              view 'ee/app/assets/javascripts/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue' do
                element :add_and_dismiss_button
              end
            end
          end

          def wait_for_license_compliance_report
            has_text?('License Compliance detected', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def approvals_required_from
            match = approvals_content.match(/approvals? from (.*)/)
            raise(ApprovalConditionsError, 'The expected approval conditions were not found.') unless match

            match[1]
          end

          def approved?
            approvals_content.include?('Approved by') && !approvals_content.match(/Requires \d+ approvals? from/)
          end

          def approvers
            within_element :approver_list_content do
              all_elements(:approver_content, minimum: 1).map { |item| item.find('img')['title'] }
            end
          end

          def click_approve
            click_element :approve_button

            find_element :approve_button, text: "Revoke approval"
          end

          def expand_license_report
            within_element(:mr_widget_extension) do
              click_element(:toggle_button)
            end
          end

          def expand_vulnerability_report
            within_element :vulnerability_report_grouped do
              click_element :expand_report_button unless has_content? 'Collapse'
            end
          end

          def click_vulnerability(name)
            within_element :vulnerability_report_grouped do
              click_on name
            end

            wait_until(reload: false) do
              find_element(:vulnerability_modal_content)
            end
          end

          def dismiss_vulnerability_with_reason(name, reason)
            expand_vulnerability_report
            click_vulnerability(name)
            add_comment_and_dismiss(reason)
          end

          def add_comment_and_dismiss(comment)
            click_element :dismiss_with_comment_button
            find_element(:dismiss_comment_field).fill_in with: comment, fill_options: { automatic_label_click: true }
            click_element :add_and_dismiss_button

            wait_until(reload: false) do
              has_no_element?(:vulnerability_modal_content)
            end
          end

          def resolve_vulnerability_with_mr(name)
            expand_vulnerability_report
            click_vulnerability(name)

            previous_page = page.current_url
            click_element :resolve_split_button

            wait_until(max_duration: 15, reload: false) do
              page.current_url != previous_page
            end
          end

          def create_vulnerability_issue(name)
            expand_vulnerability_report
            click_vulnerability(name)

            previous_page = page.current_url
            click_element(:create_issue_button)

            wait_until(max_duration: 15, reload: false) do
              page.current_url != previous_page
            end
          end

          def cancel_vulnerability_modal
            click_element(:cancel_button)
          end

          def has_vulnerability_report?(timeout: 60)
            wait_until(reload: true, max_duration: timeout, sleep_interval: 1) do
              has_element?(:vulnerability_report_grouped, wait: 10)
            end
            find_element(:vulnerability_report_grouped).has_no_content?("is loading")
          end

          def has_vulnerability_count?
            # Match text cut off in order to find both "1 vulnerability" and "X vulnerabilities"
            find_element(:vulnerability_report_grouped).has_content?(/Security scanning detected/)
          end

          def has_sast_vulnerability_count_of?(expected)
            find_element(:sast_scan_report).has_content?(/SAST detected #{expected}( new)?( potential)? vulnerabilit/)
          end

          def has_dependency_vulnerability_count_of?(expected)
            find_element(:dependency_scan_report).has_content?(/Dependency scanning detected #{expected}( new)?( potential)? vulnerabilit|Dependency scanning detected .* vulnerabilities out of #{expected}/)
          end

          def has_container_vulnerability_count_of?(expected)
            find_element(:container_scan_report).has_content?(/Container scanning detected #{expected}( new)?( potential)? vulnerabilit|Container scanning detected .* vulnerabilities out of #{expected}/)
          end

          def has_dast_vulnerability_count?
            find_element(:dast_scan_report).has_content?(/DAST detected \d*( new)?( potential)? vulnerabilit/)
          end

          def has_security_finding_dismissed_on_mr_widget?(reason)
            within_element(:vulnerability_modal_content) do
              has_element?(:event_item_content, text: /Dismissed.*/) &&
                has_element?(:event_item_content, text: reason)
            end
          end

          def has_security_finding_dismissed?(reason, project_path)
            within_element(:vulnerability_modal_content) do
              has_element?(:event_item_content, text: "Dismissed at #{project_path.gsub('/', ' / ')}") &&
                has_element?(:event_item_content, text: reason)
            end
          end

          def num_approvals_required
            approvals_content.match(/Requires (\d+) approvals/)[1].to_i
          end

          def skip_merge_train_and_merge_immediately
            click_element :merge_moment_dropdown
            click_element :merge_immediately_menu_item

            # Wait for the warning modal dialog to appear
            wait_for_animated_element :merge_immediately_button

            click_element :merge_immediately_button

            finished_loading?
          end

          def merge_via_merge_train
            try_to_merge!

            finished_loading?
          end

          private

          def approvals_content
            # The approvals widget displays "Checking approval status" briefly
            # while loading the widget, so before returning the text we wait
            # for it to include terms from content we expect. The kinds
            # of content we expect are:
            #
            # * Requires X approvals from Quality, UX, and frontend.
            # * Approved by you and others
            #
            # It can also briefly display cached data while loading so we
            # wait for it to update first
            sleep 1

            text = nil
            wait_until(reload: false, sleep_interval: 1) do
              text = find_element(:approvals_summary_content).text
              text =~ /requires|approved/i
            end

            text
          end
        end
      end
    end
  end
end
