# frozen_string_literal: true

module Types
  module Dast
    class PreScanVerificationStepType < BaseObject
      graphql_name 'DastPreScanVerificationStep'
      description 'Represents a DAST Pre Scan Verification Step'

      authorize :read_on_demand_dast_scan

      field :name, GraphQL::Types::String,
            null: true,
            deprecated: { reason: :renamed, replacement: 'DastPreScanVerificationStep.checkType', milestone: '15.10' },
            description: 'Name of the pre scan verification step.'

      field :check_type, Types::Dast::CheckTypeEnum,
            null: true,
            description: 'Type of the pre scan verification check.'

      field :errors,
            type: [GraphQL::Types::String],
            null: true,
            description: 'Errors that occurred in the pre scan verification step.',
            method: :verification_errors

      field :success,
            type: GraphQL::Types::Boolean,
            null: false,
            description: 'Whether or not the pre scan verification step has errors.',
            method: :success?
    end
  end
end
