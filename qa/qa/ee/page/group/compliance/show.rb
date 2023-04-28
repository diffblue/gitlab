# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Compliance
          class Show < QA::Page::Base
            view 'ee/app/assets/javascripts/compliance_dashboard/components/frameworks_report/projects_table.vue' do
              element :project_name_link
              element :project_path_content
              element :project_frameworks_row
            end

            view 'ee/app/assets/javascripts/compliance_dashboard/components/reports_app.vue' do
              element :frameworks_tab
            end

            view 'ee/app/assets/javascripts/compliance_dashboard/components/shared/framework_badge.vue' do
              element :framework_label
              element :framework_badge
            end

            view 'ee/app/assets/javascripts/compliance_dashboard/components/violations_report/report.vue' do
              element :violation_severity_content
              element :violation_reason_content
            end

            def click_frameworks_tab
              click_element(:frameworks_tab)
              wait_for_requests
            end

            RSpec::Matchers.define :have_violation do |reason, merge_request_title|
              match do |page|
                page.has_element?(:violation_reason_content, text: reason, description: merge_request_title)
              end

              match_when_negated do |page|
                page.has_no_element?(:violation_reason_content, text: reason, description: merge_request_title)
              end
            end

            def has_name?(name)
              verify_project_frameworks_row_scope!

              has_element?(:project_name_link, text: name, wait: 0)
            end

            def has_path?(path)
              verify_project_frameworks_row_scope!

              has_element?(:project_path_content, text: path, wait: 0)
            end

            def has_framework?(name)
              verify_project_frameworks_row_scope!

              has_element?(:framework_label, text: name, wait: 0)
            end

            def has_no_framework?
              verify_project_frameworks_row_scope!

              has_no_element?(:framework_label, wait: 0) && has_no_element?(:framework_badge, wait: 0)
            end

            def has_no_frameworks_tab?
              has_no_element?(:frameworks_tab)
            end

            def has_default_framework_badge?
              verify_project_frameworks_row_scope!

              has_element?(:framework_badge, text: 'default', wait: 0)
            end

            # Yields with the scope within the `:project_frameworks_row` element associated with the specified project.
            def project_row(project)
              within_element(:project_frameworks_row, project_name: project.name) do
                yield self
              end
            end

            def violation_severity(merge_request_title)
              find_element(:violation_severity_content, description: merge_request_title).text
            end

            private

            # Checks if the current scope is within the `:project_frameworks_row element`. If not, an error is raised.
            #
            # @return [void]
            def verify_project_frameworks_row_scope!
              return if current_scope.is_a?(Capybara::Node::Element) &&
                current_scope['data-qa-selector'].include?('project_frameworks_row')

              raise Capybara::ScopeError,
                "The calling method should be called within the `:project_frameworks_row` element via `project_row`"
            end
          end
        end
      end
    end
  end
end
