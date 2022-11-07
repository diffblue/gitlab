# frozen_string_literal: true

module Types
  module BranchRules
    class ExternalStatusCheckType < BaseObject
      graphql_name 'ExternalStatusCheck'
      description 'Describes an external status check.'
      authorize :read_external_status_check
      accepts ::MergeRequests::ExternalStatusCheck

      field :id,
            type: ::Types::GlobalIDType,
            null: false,
            description: 'ID of the rule.'

      field :name,
            type: GraphQL::Types::String,
            null: false,
            description: 'Name of the rule.'

      field :external_url,
            type: GraphQL::Types::String,
            null: false,
            description: 'External URL for the status check.'
    end
  end
end
