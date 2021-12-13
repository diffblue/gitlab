# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Jira
            class Show < QA::Page::Base
              view 'app/assets/javascripts/vue_shared/issuable/show/components/issuable_show_root.vue' do
                element :issuable_show_container
              end

              def description_content
                within_element(:issuable_show_container) do
                  find('.description').text
                end
              end

              def summary_content
                within_element(:issuable_show_container) do
                  find('.qa-title').text
                end
              end
            end
          end
        end
      end
    end
  end
end
