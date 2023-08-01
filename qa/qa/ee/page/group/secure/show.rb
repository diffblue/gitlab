# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Secure
          class Show < QA::Page::Base
            include Page::Component::SecureReport

            view 'ee/app/assets/javascripts/security_dashboard/components/pipeline/security_dashboard_table.vue' do
              element 'security-report-content', required: true
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/project_security_status_chart.vue' do
              element 'project-name-text', required: true
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/shared/filters/project_filter.vue' do
              element 'filter-project-dropdown'
            end

            def filter_project(project_id)
              click_element('filter-project-dropdown')
              find("[data-testid='listbox-item-#{project_id}']").click
            end

            def has_security_status_project_for_severity?(severity, project)
              within_element("severity_accordion_item_#{severity}") do
                click_on severity
              end
              has_element?('project-name-text', text: "#{project.group.sandbox.path} / #{project.group.path} / #{project.name}", wait: 5)
            end
          end
        end
      end
    end
  end
end
