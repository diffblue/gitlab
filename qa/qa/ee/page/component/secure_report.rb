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

              view 'ee/app/assets/javascripts/security_dashboard/components/security_dashboard_table_row.vue' do
                element :vulnerability_info_content
              end

              view 'ee/app/assets/javascripts/security_dashboard/components/
                    shared/vulnerability_report/vulnerability_list.vue' do
                element :vulnerability_status_content
              end
            end
          end

          def filter_report_type(report)
            click_element(:filter_tool_dropdown)

            click_element "filter_#{report.downcase.tr(" ", "_")}_dropdown"

            # Click the dropdown to close the modal and ensure it isn't open if this function is called again
            click_element(:filter_tool_dropdown)
          end

          def filter_by_status(statuses)
            click_element(:filter_status_dropdown)
            click_element("filter_all_statuses_dropdown")
            statuses.each do |status|
              # The data-qa-selector for this element is dynamically computed in qaSelector method in
              # ee/app/assets/javascripts/security_dashboard/components/shared/filters/filter_body.vue
              click_element("filter_#{status.downcase.tr(" ", "_")}_dropdown")
              # To account for 'All statuses' dropdown item
            end
            click_element(:filter_status_dropdown)
          end

          def has_vulnerability?(name)
            retry_until(reload: true, sleep_interval: 10, max_attempts: 12) do
              has_element?(:vulnerability, text: name)
            end
          end

          def has_vulnerability_info_content?(name)
            retry_until(reload: true, sleep_interval: 10, max_attempts: 12) do
              has_element?(:vulnerability_info_content, text: name)
            end
          end

          def has_status?(status, vulnerability_name)
            # Capitalizing first letter in each word to account for "Needs Triage" state
            has_element?(:vulnerability_status_content,
                         status_description: vulnerability_name, text: "#{status.split.map(&:capitalize).join(' ')}")
          end
        end
      end
    end
  end
end
