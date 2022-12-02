# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        class Roadmap < QA::Page::Base
          view 'ee/app/assets/javascripts/roadmap/components/epic_item_details.vue' do
            element :epic_details_cell
          end

          view 'ee/app/assets/javascripts/roadmap/components/epic_item.vue' do
            element :epic_timeline_cell
          end

          view 'ee/app/assets/javascripts/roadmap/components/roadmap_shell.vue' do
            element :roadmap_shell
          end

          def epic_present?(epic)
            epic_href_selector = "a[href*='#{epic.web_url}']"

            wait_for_requests

            within_element(:roadmap_shell) do
              find("[data-qa-selector='epic_details_cell'] #{epic_href_selector}") &&
                find("[data-qa-selector='epic_timeline_cell'] #{epic_href_selector}")
            end
          end
        end
      end
    end
  end
end
