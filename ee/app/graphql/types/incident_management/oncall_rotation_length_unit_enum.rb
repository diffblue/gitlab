# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallRotationLengthUnitEnum < BaseEnum
      graphql_name 'OncallRotationUnitEnum'
      description 'Rotation length unit of an on-call rotation'

      ::IncidentManagement::OncallRotation.length_units.keys.each do |unit|
        value unit.upcase, value: unit, description: unit.titleize
      end
    end
  end
end
