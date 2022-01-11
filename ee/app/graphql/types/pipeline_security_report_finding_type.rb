# frozen_string_literal: true

module Types
  class PipelineSecurityReportFindingType < BaseObject
    graphql_name 'PipelineSecurityReportFinding'

    description 'Represents vulnerability finding of a security report on the pipeline.'

    authorize :read_security_resource

    field :report_type,
          type: VulnerabilityReportTypeEnum,
          null: true,
          description: 'Type of the security report that found the vulnerability finding.'

    field :name,
          type: GraphQL::Types::String,
          null: true,
          description: 'Name of the vulnerability finding.'

    field :severity,
          type: VulnerabilitySeverityEnum,
          null: true,
          description: 'Severity of the vulnerability finding.'

    field :confidence,
          type: GraphQL::Types::String,
          null: true,
          description: 'Type of the security report that found the vulnerability.'

    field :false_positive,
          type: GraphQL::Types::Boolean,
          null: true,
          description: 'Indicates whether the vulnerability is a false positive.',
          resolver_method: :false_positive?

    field :scanner,
          type: VulnerabilityScannerType,
          null: true,
          description: 'Scanner metadata for the vulnerability.'

    field :identifiers,
          type: [VulnerabilityIdentifierType],
          null: false,
          description: 'Identifiers of the vulnerabilit finding.'

    field :project_fingerprint,
          type: GraphQL::Types::String,
          null: true,
          description: 'Name of the vulnerability finding.'

    field :uuid,
          type: GraphQL::Types::String,
          null: true,
          description: 'Name of the vulnerability finding.'

    field :project,
          type: ::Types::ProjectType,
          null: true,
          description: 'Project on which the vulnerability finding was found.'

    field :description,
          type: GraphQL::Types::String,
          null: true,
          description: 'Description of the vulnerability finding.'

    field :location,
          type: VulnerabilityLocationType,
          null: true,
          description: <<~DESC.squish
            Location metadata for the vulnerability.
            Its fields depend on the type of security scan that found the vulnerability.
          DESC

    field :solution,
          type: GraphQL::Types::String,
          null: true,
          description: "URL to the vulnerability's details page."

    field :state,
          type: VulnerabilityStateEnum,
          null: true,
          description: "Finding status."

    def location
      object.location&.merge(report_type: object.report_type)
    end

    def false_positive?
      return unless expose_false_positive?

      object.vulnerability_flags.any?(&:false_positive?) || false
    end

    private

    def expose_false_positive?
      object.project.licensed_feature_available?(:sast_fp_reduction)
    end
  end
end
