# frozen_string_literal: true

module Types
  module SecurityOrchestration
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the orchestration policy configuration
    # the authorization happens for that configuration
    class ScanExecutionPolicyType < BaseObject
      graphql_name 'ScanExecutionPolicy'
      description 'Represents the scan execution policy'

      implements OrchestrationPolicyType
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
