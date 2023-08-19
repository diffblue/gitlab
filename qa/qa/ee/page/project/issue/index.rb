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
                  element 'issuable-weight-content'
                end
              end
            end

            def issuable_weight
              find_element('issuable-weight-content')
            end

            def wait_for_issue_replication(issue)
              wait_until do
                filter_by_title(issue.title)

                page.has_content?(issue.title)
              end

              click_issue_link(issue.title)
            end

            def filter_by_title(title)
              filter_input = page.find('.gl-filtered-search-term-input')
              filter_input.click
              filter_input.set("#{title}:")

              filter_first_suggestion = page.find('.gl-filtered-search-suggestion-list') \
                                            .first('.gl-filtered-search-suggestion')
              filter_first_suggestion.click
            end
          end
        end
      end
    end
  end
end
