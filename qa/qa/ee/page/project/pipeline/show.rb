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

                view 'ee/app/views/projects/pipelines/_tabs_holder.html.haml' do
                  element :security_tab
                  element :licenses_tab
                  element :licenses_counter
                end
              end
            end

            def click_on_security
              retry_until(sleep_interval: 3, message: "Security report didn't open") do
                click_element(:security_tab)
                has_element?(:security_report_content)
              end
            end

            def click_on_licenses
              click_element(:licenses_tab)
            end

            def has_license_count_of?(count)
              find_element(:licenses_counter).has_content?(count)
            end

            def wait_for_pipeline_job_replication(name)
              QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_pipeline_job_replication])
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
