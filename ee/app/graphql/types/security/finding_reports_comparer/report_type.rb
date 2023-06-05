# frozen_string_literal: true

module Types
  module Security
    module FindingReportsComparer
      # rubocop: disable Graphql/AuthorizeTypes (Parent node applies authorization)
      class ReportType < BaseObject
        graphql_name 'ComparedSecurityReport'

        description 'Represents compared security report.'

        field :base_report_created_at,
          type: Types::TimeType,
          null: true,
          description: 'Time of the base report creation.'

        field :base_report_out_of_date,
          type: GraphQL::Types::Boolean,
          null: true,
          description: 'Indicates whether the base report out of date.'

        field :head_report_created_at,
          type: Types::TimeType,
          null: true,
          description: 'Time of the base report creation.'

        field :added,
          type: [FindingType],
          null: true,
          alpha: { milestone: '16.1' },
          description: 'New vulnerability findings.'

        field :fixed,
          type: [FindingType],
          null: true,
          alpha: { milestone: '16.1' },
          description: 'Fixed vulnerability findings.'

        def base_report_created_at
          Time.parse(object['base_report_created_at']) if object['base_report_created_at']
        end

        def head_report_created_at
          Time.parse(object['head_report_created_at']) if object['head_report_created_at']
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
