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
          description: 'Location metadata for the vulnerability. Its fields depend on the type of security scan that ' \
            'found the vulnerability.'

    field :solution,
          type: GraphQL::Types::String,
          null: true,
          description: "Solution for resolving the security report finding."

    field :state,
          type: VulnerabilityStateEnum,
          null: true,
          description: "Finding status."

    field :details, [::Types::VulnerabilityDetailType],
          null: false,
          resolver: Resolvers::Vulnerabilities::DetailsResolver,
          description: 'Details of the security finding.'

    # TODO: deprecate the `name` field because it's been replaced by the `title` field
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/346335
    field :name,
          type: GraphQL::Types::String,
          null: true,
          deprecated: { reason: 'Use `title`', milestone: '15.1' },
          description: 'Name of the vulnerability finding.'

    field :title,
          type: GraphQL::Types::String,
          null: true,
          description: 'Title of the vulnerability finding.', method: :name

    field :severity,
          type: VulnerabilitySeverityEnum,
          null: true,
          description: 'Severity of the vulnerability finding.'

    field :confidence,
          type: GraphQL::Types::String,
          null: true,
          description: 'Type of the security report that found the vulnerability.',
          deprecated: {
            reason: 'This field will be removed from the Finding domain model',
            milestone: '15.4'
          }

    field :false_positive,
          type: GraphQL::Types::Boolean,
          null: true,
          description: 'Indicates whether the vulnerability is a false positive.',
          resolver_method: :false_positive?

    field :links, [::Types::Vulnerabilities::LinkType],
          null: true,
          description: 'List of links associated with the vulnerability.'

    field :assets, [::Types::Vulnerabilities::AssetType],
          null: true,
          description: 'List of assets associated with the vulnerability.'

    field :evidence,
          type: VulnerabilityEvidenceType,
          null: true,
          description: 'Evidence for the vulnerability.'

    field :scanner,
          type: VulnerabilityScannerType,
          null: true,
          description: 'Scanner metadata for the vulnerability.'

    field :identifiers,
          type: [VulnerabilityIdentifierType],
          null: false,
          description: 'Identifiers of the vulnerability finding.'

    field :project_fingerprint,
          type: GraphQL::Types::String,
          null: true,
          deprecated: {
            reason: 'The `project_fingerprint` attribute is being deprecated. Use `uuid` to identify findings',
            milestone: '15.1'
          },
          description: 'Name of the vulnerability finding.'

    field :uuid,
          type: GraphQL::Types::String,
          null: true,
          description: 'UUIDv5 digest based on the vulnerability\'s report type, primary identifier, location, ' \
            'fingerprint, project identifier.'

    field :vulnerability,
          type: VulnerabilityType,
          null: true,
          description: 'Vulnerability related to the security report finding.'

    field :issue_links,
          type: ::Types::Vulnerability::IssueLinkType.connection_type,
          null: true,
          description: "List of issue links related to the vulnerability."

    markdown_field :description_html, null: true

    def vulnerability
      BatchLoader::GraphQL.for(object.uuid).batch do |uuids, loader|
        ::Vulnerability.with_findings_by_uuid(uuids).each do |vulnerability|
          loader.call(vulnerability.finding.uuid, vulnerability)
        end
      end
    end

    def issue_links
      BatchLoader::GraphQL.for(object.uuid).batch do |uuids, loader|
        ::Vulnerability.with_findings_by_uuid(uuids).each do |vulnerability|
          loader.call(vulnerability.finding.uuid, vulnerability.issue_links)
        end
      end
    end

    def location
      object.location&.merge(report_type: object.report_type)
    end

    def false_positive?
      return unless expose_false_positive?

      object.false_positive?
    end

    def description_html_resolver
      ::MarkupHelper.markdown(object.description, context.to_h.dup)
    end

    private

    def expose_false_positive?
      object.project.licensed_feature_available?(:sast_fp_reduction)
    end
  end
end
