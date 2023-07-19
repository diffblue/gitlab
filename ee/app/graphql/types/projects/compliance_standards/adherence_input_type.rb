# frozen_string_literal: true

module Types
  module Projects
    module ComplianceStandards
      class AdherenceInputType < BaseInputObject
        graphql_name 'ComplianceStandardsAdherenceInput'

        argument :project_ids, [::Types::GlobalIDType[::Project]],
          required: false,
          description: 'Filter compliance standards adherence by project.',
          prepare: ->(ids, _ctx) { ids.map(&:model_id) }

        argument :check_name, AdherenceCheckNameEnum,
          required: false,
          description: 'Name of the check for the compliance standard.'

        argument :standard, AdherenceStandardEnum,
          required: false,
          description: 'Name of the compliance standard.'
      end
    end
  end
end
