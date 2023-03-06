# frozen_string_literal: true

module Types
  module ComplianceManagement
    class ComplianceFrameworkFilterInputBaseType < BaseInputObject
      argument :id, ::Types::GlobalIDType[::ComplianceManagement::Framework],
        required: false,
        description: 'ID of the compliance framework.',
        prepare: ->(id, _ctx) { id.model_id }
    end
  end
end
