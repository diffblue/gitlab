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
              view 'app/assets/javascripts/ci/reports/components/report_item.vue' do
                element :report_item_row
              end

              view 'app/assets/javascripts/ci/reports/components/issue_status_icon.vue' do
                element :icon_status, ':data-qa-selector="`status_${status}_icon`" ' # rubocop:disable QA/ElementWithPattern
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
            within_element(:child_content, text: name) do
              has_element?(:status_success_icon, wait: 1)
            end
          end

          def has_denied_license?(name)
            within_element(:child_content, text: name) do
              has_element?(:status_failed_icon, wait: 1)
            end
          end

          def click_manage_licenses_button
            previous_page = page.current_url

            within_element(:mr_widget_extension) do
              click_element(:mr_widget_extension_actions_button, text: 'Manage Licenses')
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
