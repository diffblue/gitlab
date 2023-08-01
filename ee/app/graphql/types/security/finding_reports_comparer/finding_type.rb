# frozen_string_literal: true

module Types
  module Security
    module FindingReportsComparer
      # rubocop: disable Graphql/AuthorizeTypes (Parent node applies authorization)
      class FindingType < BaseObject
        graphql_name 'ComparedSecurityReportFinding'

        description 'Represents finding.'

        field :uuid,
          type: GraphQL::Types::String,
          null: true,
          description: 'UUIDv5 digest based on the vulnerability\'s report type, primary identifier, location, ' \
                       'fingerprint, project identifier.'

        field :title,
          type: GraphQL::Types::String,
          null: true,
          description: 'Title of the vulnerability finding.',
          hash_key: 'name'

        field :description,
          type: GraphQL::Types::String,
          null: true,
          description: 'Description of the vulnerability finding.'

        field :state,
          type: VulnerabilityStateEnum,
          null: true,
          description: 'Finding status.'

        field :severity,
          type: VulnerabilitySeverityEnum,
          null: true,
          description: 'Severity of the vulnerability finding.'

        field :found_by_pipeline_iid,
          type: GraphQL::Types::String,
          null: true,
          description: 'IID of the pipeline.'

        field :location,
          type: VulnerabilityLocationType,
          null: true,
          alpha: { milestone: '16.3' },
          description: 'Location of the vulnerability finding. Returns `null` ' \
                       'if `sast_reports_in_inline_diff` feature flag is disabled.'

        field :identifiers,
          type: [VulnerabilityIdentifierType],
          null: true,
          alpha: { milestone: '16.3' },
          description: 'Identifiers of the vulnerability finding. Returns `null` ' \
                       'if `sast_reports_in_inline_diff` feature flag is disabled.'

        def found_by_pipeline_iid
          object.dig('found_by_pipeline', 'iid')
        end

        def location
          object['location'].merge(report_type: object['report_type']) if Feature.enabled?(:sast_reports_in_inline_diff)
        end

        def identifiers
          object['identifiers'] if Feature.enabled?(:sast_reports_in_inline_diff)
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
