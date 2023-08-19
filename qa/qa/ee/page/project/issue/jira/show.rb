# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Jira
            class Show < QA::Page::Base
              view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_description.vue' do
                element 'description-content'
              end

              view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_show_root.vue' do
                element 'issuable-show-container'
              end

              view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_title.vue' do
                element 'issuable-title'
              end

              def description_content
                within_element('issuable-show-container') do
                  find_element('description-content').text
                end
              end

              def summary_content
                within_element('issuable-show-container') do
                  find_element('issuable-title').text
                end
              end
            end
          end
        end
      end
    end
  end
end
