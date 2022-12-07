# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Pipeline
          module Show
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                include Page::Component::LicenseManagement
                include Page::Component::SecureReport

                view 'ee/app/assets/javascripts/pipelines/components/pipeline_tabs.vue' do
                  element :licenses_counter
                end

                view 'app/assets/javascripts/ci/reports/components/report_item.vue' do
                  element :report_item_row
                end
              end
            end

            def click_on_security
              retry_until(sleep_interval: 3, message: "Security report didn't open") do
                click_link('Security')
                has_element?(:security_report_content)
              end
            end

            def click_on_licenses
              click_link('Licenses')
            end

            def has_approved_license?(name)
              within_element(:report_item_row, text: name) do
                has_element?(:status_success_icon, wait: 1)
              end
            end

            def has_denied_license?(name)
              within_element(:report_item_row, text: name) do
                has_element?(:status_failed_icon, wait: 1)
              end
            end

            def has_license_count_of?(count)
              find_element(:licenses_counter).has_content?(count)
            end

            def wait_for_pipeline_job_replication(name)
              QA::Runtime::Logger.debug(%Q(#{self.class.name} - wait_for_pipeline_job_replication))
              wait_until(max_duration: Runtime::Geo.max_file_replication_time) do
                has_job?(name)
              end
            end
          end
        end
      end
    end
  end
end
