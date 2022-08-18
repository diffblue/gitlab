# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module LicenseManagement
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/assets/javascripts/reports/components/report_item.vue' do
                element :report_item_row
              end

              view 'app/assets/javascripts/reports/components/issue_status_icon.vue' do
                element :icon_status, ':data-qa-selector="`status_${status}_icon`" ' # rubocop:disable QA/ElementWithPattern
              end

              view 'ee/app/assets/javascripts/vue_shared/license_compliance/mr_widget_license_report.vue' do
                element :license_report_widget
                element :manage_licenses_button
              end

              view 'app/assets/javascripts/vue_merge_request_widget/components/extensions/base.vue' do
                element :mr_widget_extension
              end

              view 'app/assets/javascripts/vue_merge_request_widget/components/action_buttons.vue' do
                element :mr_widget_extension_actions_button
              end

              view 'app/assets/javascripts/vue_merge_request_widget/components/extensions/child_content.vue' do
                element :child_content
              end
            end
          end

          def has_approved_license?(name)
            content_element = feature_flag_controlled_element(:refactor_license_compliance_extension,
                                            :child_content,
                                            :report_item_row)
            within_element(content_element, text: name) do
              has_element?(:status_success_icon, wait: 1)
            end
          end

          def has_denied_license?(name)
            content_element = feature_flag_controlled_element(:refactor_license_compliance_extension,
                                                              :child_content,
                                                              :report_item_row)
            within_element(content_element, text: name) do
              has_element?(:status_failed_icon, wait: 1)
            end
          end

          def click_manage_licenses_button
            previous_page = page.current_url

            widget_element = feature_flag_controlled_element(:refactor_license_compliance_extension,
                                                             :mr_widget_extension,
                                                             :license_report_widget)
            within_element(widget_element) do
              if widget_element == :mr_widget_extension
                click_element(:mr_widget_extension_actions_button, text: 'Manage Licenses')
              else
                click_element(:manage_licenses_button)
              end
            end
            # TODO workaround for switched to a new window UI
            wait_until(max_duration: 15, reload: false) do
              page.current_url != previous_page
            end
          end
        end
      end
    end
  end
end
