# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Iteration
          module Cadence
            class New < QA::Page::Base
              view 'ee/app/assets/javascripts/iterations/components/iteration_cadence_form.vue' do
                element :iteration_cadence_description_field
                element :iteration_cadence_start_date_field
                element :iteration_cadence_title_field, required: true
                element :save_iteration_cadence_button
              end

              def click_create_iteration_cadence_button
                click_element(:save_iteration_cadence_button)
              end

              def fill_description(description)
                fill_element(:iteration_cadence_description_field, description)
              end

              def fill_duration(duration)
                select_element(:iteration_cadence_duration_field, duration)
              end

              def fill_upcoming_iterations(upcoming_iterations)
                select_element(:iteration_cadence_upcoming_iterations_field, upcoming_iterations)
              end

              def fill_start_date(start_date)
                fill_element(:iteration_cadence_start_date_field, start_date)
                send_keys_to_element(:iteration_cadence_start_date_field, :enter)
              end

              def fill_title(title)
                fill_element(:iteration_cadence_title_field, title)
              end
            end
          end
        end
      end
    end
  end
end
