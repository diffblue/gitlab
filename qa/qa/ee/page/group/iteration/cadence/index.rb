# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Iteration
          module Cadence
            class Index < QA::Page::Base
              view 'ee/app/assets/javascripts/iterations/components/iterations.vue' do
                element :new_iteration_button
              end

              view 'ee/app/assets/javascripts/iterations/components/iteration_cadences_list.vue' do
                element :cadence_list_item_content
                element :create_new_cadence_button, required: true
              end

              view 'ee/app/assets/javascripts/iterations/components/iteration_cadence_list_item.vue' do
                element :cadence_options_button
              end

              def click_new_iteration_cadence_button
                click_element(:create_new_cadence_button)
              end

              def click_new_iteration_button(cadence_title)
                cadence = find_element(:cadence_list_item_content, text: cadence_title)
                within cadence do
                  click_element(:cadence_options_button)
                  click_element(:new_iteration_button)
                end
              end
            end
          end
        end
      end
    end
  end
end
