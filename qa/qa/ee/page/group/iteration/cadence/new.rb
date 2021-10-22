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
                element :iteration_cadence_automated_scheduling_checkbox
                element :save_iteration_cadence_button
              end

              def click_create_iteration_cadence_button
                click_element(:save_iteration_cadence_button)
              end

              def fill_description(description)
                fill_element(:iteration_cadence_description_field, description)
              end

              def fill_start_date(start_date)
                fill_element(:iteration_cadence_start_date_field, start_date)
              end

              def fill_title(title)
                fill_element(:iteration_cadence_title_field, title)
              end

              def uncheck_automatic_scheduling
                uncheck_element(:iteration_cadence_automated_scheduling_checkbox, true)
              end
            end
          end
        end
      end
    end
  end
end
