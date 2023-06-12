# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class ValueStreamAnalytics < QA::Page::Base
          view "ee/app/assets/javascripts/analytics/cycle_analytics/components/value_stream_empty_state.vue" do
            element :create_value_stream_button
          end

          view "ee/app/assets/javascripts/analytics/cycle_analytics/components/value_stream_form_content.vue" do
            element :value_stream_form_modal
            element :create_value_stream_name_input
          end

          view "ee/app/assets/javascripts/analytics/cycle_analytics/components/base.vue" do
            element :vsa_path_navigation
          end

          # Create new value stream from empty state
          #
          # @return [void]
          def create_new_value_stream_from_default_template(name)
            click_element(:create_value_stream_button)
            fill_element(:create_value_stream_name_input, name)

            within_element(:value_stream_form_modal) do
              # footer buttons are generic UI components from gitlab/ui
              find_button("Create value stream").click
            end
          end
        end
      end
    end
  end
end
