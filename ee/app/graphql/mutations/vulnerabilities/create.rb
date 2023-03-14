# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Create < BaseMutation
      graphql_name 'VulnerabilityCreate'

      authorize :admin_vulnerability

      argument :project, ::Types::GlobalIDType[::Project],
        required: true,
        description: 'ID of the project to attach the vulnerability to.'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Name of the vulnerability.'

      argument :description, GraphQL::Types::String,
        required: true,
        description: 'Long text section that describes the vulnerability in more detail.'

      argument :scanner, Types::VulnerabilityScannerInputType,
        required: true,
        description: 'Information about the scanner used to discover the vulnerability.'

      argument :identifiers, [Types::VulnerabilityIdentifierInputType],
        required: true,
        description: 'Array of CVE or CWE identifiers for the vulnerability.'

      argument :state, Types::VulnerabilityStateEnum,
        required: false,
        description: 'State of the vulnerability (defaults to `detected`).',
        default_value: 'detected'

      argument :severity, Types::VulnerabilitySeverityEnum,
        required: false,
        description: 'Severity of the vulnerability (defaults to `unknown`).',
        default_value: 'unknown'

      argument :confidence, Types::VulnerabilityConfidenceEnum,
        required: false,
        description: 'Confidence of the vulnerability (defaults to `unknown`).',
        default_value: 'unknown',
        deprecated: {
          reason: 'This field will be removed from the Vulnerability domain model',
          milestone: '15.4'
        }

      argument :solution, GraphQL::Types::String,
        required: false,
        description: 'Instructions for how to fix the vulnerability.'

      argument :message, GraphQL::Types::String,
        required: false,
        description: "Short text section that describes the vulnerability. This may include the finding's specific information."

      argument :detected_at, Types::TimeType,
        required: false,
        description: 'Timestamp of when the vulnerability was first detected (defaults to creation time).'

      argument :confirmed_at, Types::TimeType,
        required: false,
        description: 'Timestamp of when the vulnerability state changed to confirmed (defaults to creation time if status is `confirmed`).'

      argument :resolved_at, Types::TimeType,
        required: false,
        description: 'Timestamp of when the vulnerability state changed to resolved (defaults to creation time if status is `resolved`).'

      argument :dismissed_at, Types::TimeType,
        required: false,
        description: 'Timestamp of when the vulnerability state changed to dismissed (defaults to creation time if status is `dismissed`).'

      field :vulnerability, Types::VulnerabilityType,
        null: true,
        description: 'Vulnerability created.'

      def resolve(**attributes)
        project = authorized_find!(id: attributes.fetch(:project))

        params = build_vulnerability_params(attributes)

        result = ::Vulnerabilities::ManuallyCreateService.new(
          project,
          current_user,
          params: params
        ).execute

        {
          vulnerability: result.payload[:vulnerability],
          errors: result.success? ? [] : Array(result.message)
        }
      end

      private

      def build_vulnerability_params(params)
        vulnerability_params = params.slice(
          *%i[
            name
            state
            severity
            confidence
            message
            description
            solution
            detected_at
            confirmed_at
            resolved_at
            dismissed_at
            identifiers
            scanner
          ])

        {
          vulnerability: vulnerability_params
        }
      end
    end
  end
end
