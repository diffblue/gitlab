# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Jira
            class Index < QA::Page::Base
              view 'app/assets/javascripts/vue_shared/issuable/list/components/issuable_list_root.vue' do
                element :issuable_search_container
                element :issuable_container
              end

              def search_issues(issue_search_text)
                within_element(:issuable_search_container) do
                  find('input.gl-filtered-search-term-input').click
                  find('input[aria-label="Search"]').set(issue_search_text)
                  find('button[aria-label="Search"]').click
                end
                wait_for_loading
              end

              def visible_issues
                find_all('li.issue')
              end

              def click_issue(issue_key)
                id = issue_key.split('-')[-1]
                within_element(:issuable_container, issue_id: id) do
                  find('a.issue-title-text').click
                end
              end

              def wait_for_loading
                QA::Support::Waiter.wait_until(max_duration: 10, raise_on_failure: false) do
                  !has_css?('div.animation-container')
                end
              end
            end
          end
        end
      end
    end
  end
end
