# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Iteration
          module Cadence
            class Index < QA::Page::Base
              view 'ee/app/assets/javascripts/iterations/components/iteration_cadences_list.vue' do
                element :cadence_list_item_content
                element :create_new_cadence_button, required: true
              end

              view 'ee/app/assets/javascripts/iterations/components/iteration_cadence_list_item.vue' do
                element :cadence_options_button
                element :iteration_item
                element :new_iteration_button
              end

              def click_new_iteration_cadence_button
                click_element(:create_new_cadence_button)
              end

              def open_iteration(cadence_title, iteration_period)
                cadence = toggle_iteration_cadence_dropdown(cadence_title)
                within cadence do
                  click_iteration(iteration_period)
                end
              end

              private

              def click_iteration(iteration_period)
                click_element(:iteration_item, title: iteration_period)
              end

              def toggle_iteration_cadence_dropdown(cadence_title)
                find_element(:cadence_list_item_content, text: cadence_title).click
              end
            end
          end
        end
      end
    end
  end
end
