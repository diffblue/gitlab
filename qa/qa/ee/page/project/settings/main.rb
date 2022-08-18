# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module Main
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'ee/app/views/projects/settings/_default_issue_template.html.haml' do
                  element :issue_template_settings_content
                end

                view 'ee/app/views/projects/settings/merge_requests/_merge_request_approvals_settings.html.haml' do
                  element :merge_request_approvals_settings_content
                end
              end
            end

            def expand_default_description_template_for_issues(&block)
              expand_content(:issue_template_settings_content) do
                IssueTemplateDefault.perform(&block)
              end
            end
          end
        end
      end
    end
  end
end
