# frozen_string_literal: true

module Integrations
  module JiraSerializers
    class IssueEntity < Grape::Entity
      include RequestAwareEntity

      expose :project_id do |_jira_issue|
        project.id
      end

      expose :title do |jira_issue|
        jira_issue.summary
      end

      expose :title_html do |jira_issue|
        html_escape jira_issue.summary
      end

      expose :created_at do |jira_issue|
        jira_issue.created.to_datetime.utc
      end

      expose :updated_at do |jira_issue|
        jira_issue.updated.to_datetime.utc
      end

      expose :closed_at do |jira_issue|
        jira_issue.resolutiondate&.to_datetime&.utc
      end

      expose :status do |jira_issue|
        jira_issue.status.name
      end

      expose :labels do |jira_issue|
        jira_issue.labels.map do |name|
          {
            id: name,
            title: name,
            name: name,
            color: '#0052CC',
            text_color: '#FFFFFF'
          }
        end
      end

      expose :author do |jira_issue|
        jira_user(jira_issue.fields['reporter'])
      end

      expose :assignees do |jira_issue|
        if jira_issue.fields['assignee']
          [
            jira_user(jira_issue.fields['assignee'])
          ]
        else
          []
        end
      end

      expose :web_url do |jira_issue|
        project.jira_integration.issue_url(jira_issue.key)
      end

      expose :gitlab_web_url do |jira_issue|
        project_integrations_jira_issue_path(project, jira_issue.key)
      end

      expose :references do |jira_issue|
        {
          relative: jira_issue.key
        }
      end

      expose :external_tracker do |_jira_issue|
        'jira'
      end

      private

      def jira_user(user)
        {
          id: jira_user_id(user),
          name: user['displayName'],
          web_url: jira_web_url(user),
          avatar_url: user['avatarUrls']['48x48']
        }
      end

      def jira_user_id(user)
        # There are differences between Jira Cloud and Jira Server URLs and responses.
        # accountId is only available on Jira Cloud.
        # https://community.atlassian.com/t5/Jira-Questions/How-to-find-account-id-on-jira-on-premise/qaq-p/1168652
        user['accountId'].presence || user['name']
      end

      def jira_web_url(user)
        # There are differences between Jira Cloud and Jira Server URLs and responses.
        # accountId is only available on Jira Cloud.
        # https://community.atlassian.com/t5/Jira-Questions/How-to-find-account-id-on-jira-on-premise/qaq-p/1168652
        if user['accountId'].present?
          project.jira_integration.web_url("people/#{user['accountId']}")
        else
          project.jira_integration.web_url('secure/ViewProfile.jspa', name: user['name'])
        end
      end

      def project
        @project ||= options[:project]
      end
    end
  end
end
