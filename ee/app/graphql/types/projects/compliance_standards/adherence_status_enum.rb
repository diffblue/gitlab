# frozen_string_literal: true

module Types
  module Projects
    module ComplianceStandards
      class AdherenceStatusEnum < BaseEnum
        graphql_name 'ComplianceStandardsAdherenceStatus'
        description 'Status of the compliance standards adherence.'

        ::Enums::Projects::ComplianceStandards::Adherence.status.each_key do |status|
          value status.to_s.upcase, value: status.to_s, description: status.to_s.humanize
        end
      end
    end
  end
end
