# frozen_string_literal: true

module Types
  module SecurityOrchestration
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the orchestration policy configuration
    # the authorization happens for that configuration
    class ScanResultPolicyType < BaseObject
      graphql_name 'ScanResultPolicy'
      description 'Represents the scan result policy'

      implements OrchestrationPolicyType

      field :group_approvers, ['::Types::GroupType'], null: true, description: 'Approvers of the group type.'
      field :user_approvers, [::Types::UserType], null: true, description: 'Approvers of the user type.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
