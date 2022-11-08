# frozen_string_literal: true

module Integrations
  module JiraSerializers
    class IssueDetailEntity < ::Integrations::JiraSerializers::IssueEntity
      expose :description_html do |jira_issue|
        jira_gfm_pipeline(jira_issue.renderedFields['description'])
      end

      expose :state do |jira_issue|
        jira_issue.resolutiondate ? 'closed' : 'opened'
      end

      expose :due_date do |jira_issue|
        jira_issue.duedate&.to_datetime&.utc
      end

      expose :comments do |jira_issue|
        jira_issue.fields['comment']['comments'].map.with_index do |comment, index|
          {
            id: comment['id'],
            body_html: jira_gfm_pipeline(jira_issue.renderedFields['comment']['comments'][index]['body']),
            created_at: comment['created'].to_datetime.utc,
            updated_at: comment['updated'].to_datetime.utc,
            author: jira_user(comment['author'])
          }
        end
      end

      private

      def jira_gfm_pipeline(raw)
        rendered = Banzai::Pipeline::JiraGfmPipeline.call(raw, project: project)[:output].to_html
        Banzai.post_process(rendered, project: project, current_user: current_user)
      end

      def current_user
        @current_user ||= options[:current_user]
      end
    end
  end
end
