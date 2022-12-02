# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Show
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'app/assets/javascripts/sidebar/components/sidebar_editable_item.vue' do
                  element :edit_link
                end

                view 'ee/app/assets/javascripts/sidebar/components/iteration/sidebar_iteration_widget.vue' do
                  element :iteration_link
                end

                view 'app/views/shared/issuable/_sidebar.html.haml' do
                  element :iteration_container
                end

                view 'ee/app/assets/javascripts/sidebar/components/weight/sidebar_weight_widget.vue' do
                  element :weight_label_value
                end
              end
            end

            def assign_iteration(iteration_period)
              within_element(:iteration_container) do
                click_element(:edit_link)
                click_on("#{iteration_period}")
              end

              wait_until(reload: false) do
                has_element?(:iteration_container, text: iteration_period, wait: 0)
              end

              refresh
            end

            def click_iteration(iteration_period)
              has_iteration?(iteration_period)

              within_element(:iteration_container) do
                click_element(:iteration_link, text: iteration_period)
              end
            end

            def has_iteration?(iteration_period)
              wait_until_iteration_container_loaded

              within_element(:iteration_container) do
                wait_until(reload: false) do
                  has_element?(:iteration_link, text: iteration_period, wait: 0)
                end
              end
            end

            def wait_for_attachment_replication(image_url, max_wait: Runtime::Geo.max_file_replication_time)
              QA::Runtime::Logger.debug(%Q[#{self.class.name} - wait_for_attachment_replication])
              wait_until_geo_max_replication_time(max_wait: max_wait) do
                asset_exists?(image_url)
              end
            end

            def weight_label_value
              find_element(:weight_label_value)
            end

            private

            def wait_until_geo_max_replication_time(max_wait: Runtime::Geo.max_file_replication_time, &block)
              wait_until(max_duration: max_wait, &block)
            end

            def wait_until_iteration_container_loaded
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                has_element?(:iteration_container)
                has_element?(:iteration_link)
              end
            end
          end
        end
      end
    end
  end
end
