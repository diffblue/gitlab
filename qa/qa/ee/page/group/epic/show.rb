# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Show < QA::Page::Base
            include QA::Page::Component::Issuable::Common
            include QA::Page::Component::Note

            view 'ee/app/assets/javascripts/epic/components/epic_header.vue' do
              element :close_reopen_epic_button
            end

            view 'app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
              element :add_issue_button
            end

            view 'app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
              element :add_issue_field
            end

            view 'ee/app/assets/javascripts/related_items_tree/components/epic_issue_actions_split_button.vue' do
              element :epic_issue_actions_split_button
            end

            view 'ee/app/assets/javascripts/related_items_tree/components/tree_item.vue' do
              element :related_issue_item
            end

            view 'ee/app/assets/javascripts/related_items_tree/components/tree_item_body.vue' do
              element :remove_issue_button
            end

            def add_issue_to_epic(issue_url)
              click_element(:epic_issue_actions_split_button)
              find('button', text: 'Add an existing issue').click
              fill_element :add_issue_field, issue_url
              # Clicking the title blurs the input
              click_element :title_content
              click_element :add_issue_button
            end

            def remove_issue_from_epic
              click_element :remove_issue_button
              # Capybara code is used below due to the modal being defined in the @gitlab/ui project
              find('#item-remove-confirmation___BV_modal_footer_ .btn-danger').click
            end

            def close_reopen_epic
              click_element :close_reopen_epic_button
            end

            def has_related_issue_item?
              has_element?(:related_issue_item)
            end

            def has_no_related_issue_item?
              has_no_element?(:related_issue_item)
            end
          end
        end
      end
    end
  end
end
