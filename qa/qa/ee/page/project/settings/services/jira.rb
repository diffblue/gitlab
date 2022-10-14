# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module Services
            module Jira
              extend QA::Page::PageConcern
              def self.prepended(base)
                super

                base.class_eval do
                  view 'ee/app/assets/javascripts/integrations/edit/components/' \
                    'jira_issue_creation_vulnerabilities.vue' do
                    element :service_jira_enable_vulnerabilities_checkbox
                    element :service_jira_issue_types_fetch_retry_button
                    element :service_jira_select_issue_type_dropdown
                    element :service_jira_type
                  end
                end
              end

              def enable_jira_vulnerabilities
                check_element(:service_jira_enable_vulnerabilities_checkbox, true)
              end

              def select_vulnerability_bug_type(bug_type)
                click_retry_vulnerabilities
                select_jira_bug_type(bug_type)
              end

              private

              def click_retry_vulnerabilities
                click_element(:service_jira_issue_types_fetch_retry_button)
              end

              def select_jira_bug_type(option)
                click_element(:service_jira_select_issue_type_dropdown)
                click_element(:service_jira_type, service_type: option)
              end
            end
          end
        end
      end
    end
  end
end
