# frozen_string_literal: true

module QA
  module EE
    module Page
      module Component
        module IssueBoard
          module Show
            extend QA::Page::PageConcern

            def self.prepended(base)
              super
              base.class_eval do
                view 'ee/app/assets/javascripts/boards/components/board_scope.vue' do
                  element :board_scope_modal
                end

                view 'ee/app/assets/javascripts/boards/components/labels_select.vue' do
                  element :labels_edit_button
                end

                view 'app/assets/javascripts/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue' do
                  element :labels_dropdown_content
                end
              end
            end

            def board_scope_modal
              find_element(:board_scope_modal)
            end

            def configure_by_label(label)
              click_boards_config_button

              QA::Support::Retrier.retry_on_exception do
                click_element(:labels_edit_button)
                find_element(:labels_dropdown_content)
              end

              find_element(:labels_dropdown_content).find('li', text: label).click
              # Clicking the edit button again closes the dropdown and allows the save button to be clicked
              click_element(:labels_edit_button)
              click_element(:save_changes_button)
              wait_boards_list_finish_loading
            end
          end
        end
      end
    end
  end
end
