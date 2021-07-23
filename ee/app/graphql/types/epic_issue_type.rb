# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  # This is a subclass of `IssueType` which has authorization
  class EpicIssueType < IssueType
    graphql_name 'EpicIssue'
    description 'Relationship between an epic and an issue'

    present_using EpicIssuePresenter

    field :epic_issue_id, GraphQL::Types::ID, null: false,
          description: 'ID of the epic-issue relation.'

    field :relation_path, GraphQL::Types::String, null: true,
          description: 'URI path of the epic-issue relation.'

    field :id, GraphQL::Types::ID, null: true,
          description: 'Global ID of the epic-issue relation.'

    def epic_issue_id
      "gid://gitlab/EpicIssue/#{object.epic_issue_id}"
    end

    def relation_path
      object.group_epic_issue_path(context[:current_user])
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
