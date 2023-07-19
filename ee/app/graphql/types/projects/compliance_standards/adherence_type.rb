# frozen_string_literal: true

module Types
  module Projects
    module ComplianceStandards
      class AdherenceType < ::Types::BaseObject
        graphql_name 'ComplianceStandardsAdherence'
        description 'Compliance standards adherence for a project.'

        authorize :read_group_compliance_dashboard

        field :id, GraphQL::Types::ID,
          null: false, description: 'Compliance standards adherence ID.'

        field :updated_at, Types::TimeType,
          null: false, description: 'Timestamp when the adherence was updated.'

        field :status, AdherenceStatusEnum,
          null: false, description: 'Status of the compliance standards adherence.'

        field :check_name, AdherenceCheckNameEnum,
          null: false, description: 'Name of the check for the compliance standard.'

        field :standard, AdherenceStandardEnum,
          null: false, description: 'Name of the compliance standard.'

        field :project, ::Types::ProjectType,
          null: false, description: 'Project adhering to the compliance standard.'
      end
    end
  end
end
