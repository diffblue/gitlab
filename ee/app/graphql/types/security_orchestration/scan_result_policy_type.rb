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
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
