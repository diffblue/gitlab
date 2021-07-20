# frozen_string_literal: true

module EE
  module Integrations
    module Jira
      extend ActiveSupport::Concern

      MAX_URL_LENGTH = 4000

      prepended do
        validates :project_key, presence: true, if: :project_key_required?
        validates :vulnerabilities_issuetype, presence: true, if: :vulnerabilities_enabled
      end

      def jira_vulnerabilities_integration_available?
        parent.present? ? parent.licensed_feature_available?(:jira_vulnerabilities_integration) : License.feature_available?(:jira_vulnerabilities_integration)
      end

      def jira_vulnerabilities_integration_enabled?
        jira_vulnerabilities_integration_available? && vulnerabilities_enabled
      end

      def configured_to_create_issues_from_vulnerabilities?
        strong_memoize(:configured_to_create_issues_from_vulnerabilities) do
          active? && project_key.present? && vulnerabilities_issuetype.present? && jira_vulnerabilities_integration_enabled?
        end
      end

      def test(_)
        super.then do |result|
          next result unless result[:success]
          next result unless project.jira_vulnerabilities_integration_enabled?

          result.merge(data: { issuetypes: issue_types })
        end
      end

      def new_issue_url_with_predefined_fields(summary, description)
        escaped_summary = CGI.escape(summary)
        escaped_description = CGI.escape(description)

        # Put summary and description at the end of the URL in case we need to trim it
        web_url('secure/CreateIssueDetails!init.jspa', pid: jira_project_id, issuetype: vulnerabilities_issuetype)
          .concat("&summary=#{escaped_summary}&description=#{escaped_description}")
          .slice(0..MAX_URL_LENGTH)
      end

      def create_issue(summary, description, current_user)
        return if client_url.blank?

        jira_request do
          issue = client.Issue.build
          issue.save(
            fields: {
              project: { id: jira_project_id },
              issuetype: { id: vulnerabilities_issuetype },
              summary: summary,
              description: description
            }
          )
          log_usage(:create_issue, current_user)
          issue
        end
      end

      private

      def project_key_required?
        strong_memoize(:project_key_required) do
          issues_enabled || vulnerabilities_enabled
        end
      end

      # Returns internal JIRA Project ID
      #
      # @return [String, nil] the internal JIRA ID of the Project
      def jira_project_id
        jira_project&.id
      end

      # Returns JIRA Project for selected Project Key
      #
      # @return [JIRA::Resource::Project, nil] the object that represents JIRA Projects
      def jira_project
        strong_memoize(:jira_project) do
          client_url.present? ? jira_request { client.Project.find(project_key) } : nil
        end
      end

      # Returns list of available Issue types in selected JIRA Project
      #
      # @return [Array] the array of objects with JIRA Issuetype ID, Name and Description
      def issue_types
        return [] if jira_project.blank?

        jira_project
          .issuetypes
          .reject { |issue_type| issue_type.subtask }
          .map do |issue_type|
          {
            id: issue_type.id,
            name: issue_type.name,
            description: issue_type.description
          }
        end
      end
    end
  end
end
