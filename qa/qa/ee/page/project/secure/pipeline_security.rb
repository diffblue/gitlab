# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Secure
          class PipelineSecurity < QA::Page::Base
            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/security_dashboard_table_row.vue' do
              element :vulnerability_info_content
              element :security_finding_name_button
              element :security_finding_checkbox
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/vulnerability_action_buttons.vue' do
              element :finding_dismiss_symbol_button
              element :finding_create_issue_button
              element :finding_undo_dismiss_button
              element :finding_more_info_button
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/filters.vue' do
              element :findings_hide_dismissed_toggle
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/selection_summary_vuex.vue' do
              element :finding_dismissal_reason
              element :finding_dismiss_button
            end

            def dismiss_finding_with_reason(finding_name, reason)
              check_element(:security_finding_checkbox, true, finding_name: finding_name, visible: false)
              select_element(:finding_dismissal_reason, reason)
              click_element(:finding_dismiss_button)
            end

            def toggle_hide_dismissed_off
              toggle_hide_dismissed("off")
            end

            def toggle_hide_dismissed_on
              toggle_hide_dismissed("on")
            end

            def toggle_hide_dismissed(toggle_to)
              within_element(:findings_hide_dismissed_toggle) do
                toggle = find('button.gl-toggle')
                checked = toggle[:class].include?('is-checked')
                toggle.click if checked && toggle_to == "off" || !checked && toggle_to == "on"
              end
            end

            def undo_dismiss_button_present?(finding_name)
              has_element?(:finding_undo_dismiss_button, finding_name: finding_name)
            end

            def create_issue(finding_name)
              click_element(:finding_create_issue_button, QA::Page::Project::Issue::Show, finding_name: finding_name)
            end

            def expand_security_finding(finding_name)
              click_element(:finding_more_info_button, finding_name: finding_name)
            end
          end
        end
      end
    end
  end
end
