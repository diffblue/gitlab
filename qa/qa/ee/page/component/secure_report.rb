# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module SecureReport
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'ee/app/assets/javascripts/security_dashboard/components/filters/simple_filter.vue' do
                element :filter_dropdown, ':data-qa-selector="qaSelector"' # rubocop:disable QA/ElementWithPattern
                element :filter_dropdown_content
              end

              view 'ee/app/assets/javascripts/security_dashboard/components/security_dashboard_table.vue' do
                element :security_report_content
              end

              view 'ee/app/assets/javascripts/security_dashboard/components/shared/filters/activity_filter.vue' do
                element :filter_activity_dropdown
              end

              view 'ee/app/assets/javascripts/security_dashboard/components/
                    shared/vulnerability_report/vulnerability_list.vue' do
                element :vulnerability_status_content
              end
            end
          end

          def filter_report_type(report)
            click_element(:filter_tool_dropdown)

            click_element "filter_#{report.downcase.tr(" ", "_")}_dropdown_item"

            # Click the dropdown to close the modal and ensure it isn't open if this function is called again
            click_element(:filter_tool_dropdown)
          end

          def filter_by_status(statuses)
            wait_until(max_duration: 30, message: "Waiting for status dropdown element to appear") do
              has_element?(:filter_status_dropdown)
            end

            # Retry on exception to avoid ElementNotFound errors when clicks are sent too fast for the UI to update
            retry_on_exception(sleep_interval: 2, message: "Retrying status click until current url matches state") do
              click_element(:filter_status_dropdown)
              click_element("filter_all_statuses_dropdown_item")
              statuses.each do |status|
                # The data-qa-selector for this element is dynamically computed in qaSelector method in
                # ee/app/assets/javascripts/security_dashboard/components/shared/filters/filter_body.vue
                click_element("filter_#{status.downcase.tr(" ", "_")}_dropdown_item")
                # To account for 'All statuses' dropdown item
                wait_for_requests # It takes a moment to update the page after changing selections
              end
              click_element(:filter_status_dropdown)
              state = statuses.map do |status|
                case status
                when /all/i
                  'state=all'
                when /needs triage/i
                  'state=detected'
                else
                  "state=#{status}"
                end
              end.join("&")
              page.current_url.downcase.include?(state)
            end
          end

          def filter_by_activity(activity_name)
            # Even though we can add a selector here it's not enough on it's own because it appears on several elements
            # We use the `> button` selector to avoid an ambiguous match error
            selector = "[data-qa-selector='filter_activity_dropdown'] > button"
            act_via_capybara(:find, selector, wait: 30).click
            click_element("filter_#{activity_name.downcase.tr(" ", "_")}_dropdown_item")
            act_via_capybara(:find, selector).click
          end

          def has_vulnerability?(name)
            retry_until(reload: true, sleep_interval: 10, max_attempts: 6, message: "Retry for vulnerability text") do
              has_element?(:vulnerability, text: name)
            end
          end

          def has_vulnerability_info_content?(name)
            retry_until(reload: true, sleep_interval: 2, max_attempts: 3) do
              click_link('Security') unless has_element?(:security_report_content)
              has_element?(:vulnerability_info_content, text: name)
            end
          end

          def has_status?(status, vulnerability_name)
            retry_until(reload: true, sleep_interval: 3, raise_on_failure: false) do
              # Capitalizing first letter in each word to account for "Needs Triage" state
              has_element?(:vulnerability_status_content,
                           status_description: vulnerability_name, text: "#{status.split.map(&:capitalize).join(' ')}")
            end
          end
        end
      end
    end
  end
end
