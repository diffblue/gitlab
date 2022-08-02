# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes
      class VerificationStatusType < BaseObject
        graphql_name 'WorkItemWidgetVerificationStatus'
        description 'Represents a verification status widget'

        implements Types::WorkItems::WidgetInterface

        field :verification_status, GraphQL::Types::String, null: true,
              description: 'Verification status of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
