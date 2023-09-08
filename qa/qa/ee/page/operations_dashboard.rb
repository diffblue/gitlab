# frozen_string_literal: true

module QA
  module EE
    module Page
      class OperationsDashboard < QA::Page::Base
        include QA::Page::Component::ProjectSelector
        include QA::Page::Component::CiBadgeLink

        view 'ee/app/assets/javascripts/operations/components/dashboard/dashboard.vue' do
          element 'add-projects-button'
          element 'add-projects-modal'
        end

        view 'ee/app/assets/javascripts/operations/components/dashboard/project.vue' do
          element 'dashboard-project-card'
        end

        view 'ee/app/assets/javascripts/operations/components/dashboard/project_header.vue' do
          element 'remove-project-button'
        end

        def add_project(project_name)
          open_add_project_modal

          within_add_projects_modal do
            fill_project_search_input(project_name)
            select_project
            find('button.btn.btn-confirm').click
          end
        end

        def has_project_card?
          has_element? 'dashboard-project-card'
        end

        def find_project_card_by_name(name)
          project_cards.each do |card|
            title = card.find('div.card-header').find('a.gl-link')[:title]
            return card if title.include? name
          end
        end

        def pipeline_status(project_card)
          project_card.find(element_selector_css(:status_badge_link)).text
        end

        private

        def project_cards
          all_elements('dashboard-project-card', minimum: 1)
        end

        def remove_project_buttons
          all_elements('remove-project-button', minimum: 1)
        end

        def within_add_projects_modal(&block)
          within_element('add-projects-modal', &block)
        end

        def open_add_project_modal
          click_element 'add-projects-button'
        end
      end
    end
  end
end
