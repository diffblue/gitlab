# frozen_string_literal: true

module Types
  class PushRulesType < BaseObject
    graphql_name 'PushRules'
    description 'Represents rules that commit pushes must follow.'
    accepts ::PushRule

    authorize :read_project

    field :reject_unsigned_commits,
      GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates whether commits not signed through GPG will be rejected.'

    def reject_unsigned_commits
      !!(object.available?(:reject_unsigned_commits) && object.reject_unsigned_commits)
    end
  end
end
