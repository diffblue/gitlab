# frozen_string_literal: true

module Types
  module Dast
    class PreScanVerificationType < BaseObject
      graphql_name 'DastPreScanVerification'
      description 'Represents a DAST Pre Scan Verification'

      authorize :read_on_demand_dast_scan

      field :status, Types::Dast::PreScanVerificationStatusEnum,
            null: true,
            description: 'Status of the pre scan verification.'

      field :pre_scan_verification_steps,
            type: [Types::Dast::PreScanVerificationStepType],
            null: true,
            description: 'Pre Scan Verifications Steps.'

      field :valid,
            type: GraphQL::Types::Boolean,
            null: false,
            description: 'Whether or not the configuration has changed after the last pre scan run.',
            method: :verification_valid?
    end
  end
end
