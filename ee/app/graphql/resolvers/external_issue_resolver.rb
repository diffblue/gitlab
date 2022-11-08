# frozen_string_literal: true

module Resolvers
  class ExternalIssueResolver < BaseResolver
    description 'Retrieve a single issue from external tracker'

    type Types::ExternalIssueType, null: true

    def resolve
      BatchLoader::GraphQL.for(object.external_issue_key).batch(key: object.external_type) do |external_issue_keys, loader, args|
        case args[:key]
        when 'jira'
          jira_issues(external_issue_keys).each do |external_issue|
            loader.call(
              external_issue.id,
              serialize_external_issue(external_issue, args[:key])
            )
          end
        end
      end
    end

    private

    def jira_issues(issue_ids)
      result = ::Projects::Integrations::Jira::ByIdsFinder.new(object.vulnerability.project, issue_ids).execute
      return [] if result.nil?

      raise GraphQL::ExecutionError, result[:error] if result[:error].present?

      result[:issues]
    end

    def serialize_external_issue(external_issue, external_type)
      case external_type
      when 'jira'
        ::Integrations::JiraSerializers::IssueSerializer
          .new
          .represent(external_issue, project: object.vulnerability.project, only: %i[title references status external_tracker web_url created_at updated_at])
      end
    end
  end
end
