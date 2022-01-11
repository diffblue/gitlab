# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Index
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/assets/javascripts/issues/list/components/issue_card_time_info.vue' do
                  element :issuable_weight_content
                end
              end
            end

            def issuable_weight
              find_element(:issuable_weight_content)
            end

            def wait_for_issue_replication(issue)
              wait_until do
                filter_by_title(issue.title)

                page.has_content?(issue.title)
              end

              click_issue_link(issue.title)
            end

            def filter_by_title(title)
              within_element(:issuable_search_container) do
                fill_in class: 'gl-filtered-search-term-input', with: title
              end
            end
          end
        end
      end
    end
  end
end
