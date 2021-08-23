# frozen_string_literal: true

module Mutations
  module Vulnerabilities
    class Create < BaseMutation
      graphql_name 'VulnerabilityCreate'

      authorize :admin_vulnerability

      argument :project, ::Types::GlobalIDType[::Project],
        required: true,
        description: 'ID of the project to attach the vulnerability to.'

      argument :title, GraphQL::Types::String,
        required: true,
        description: 'Title of the vulnerability.'

      argument :description, GraphQL::Types::String,
        required: true,
        description: 'Description of the vulnerability.'

      argument :scanner_type, Types::SecurityScannerTypeEnum,
        required: true,
        description: 'Type of the security scanner used to discover the vulnerability.'

      argument :scanner_name, GraphQL::Types::String,
        required: true,
        description: 'Name of the security scanner used to discover the vulnerability.'

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
        default_value: 'unknown'

      argument :solution, GraphQL::Types::String,
        required: false,
        description: 'How to fix this vulnerability.'

      argument :message, GraphQL::Types::String,
        required: false,
        description: 'Additional information about the vulnerability.'

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

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless Feature.enabled?(:create_vulnerabilities_via_api, project)

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

      def find_object(id:)
        # TODO: remove explicit coercion once compatibility layer has been removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Project].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end

      def build_vulnerability_params(params)
        vulnerability_params = params.slice(*%i[
          title
          state
          severity
          confidence
          message
          solution
          detected_at
          confirmed_at
          resolved_at
          dismissed_at
          identifiers
        ])

        scanner_params = {
          name: params.fetch(:scanner_name),
          type: params.fetch(:scanner_type)
        }

        {
          vulnerability: vulnerability_params
            .merge(scanner: scanner_params)
        }
      end
    end
  end
end
