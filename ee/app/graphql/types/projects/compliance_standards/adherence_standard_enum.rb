# frozen_string_literal: true

module Types
  module Projects
    module ComplianceStandards
      class AdherenceStandardEnum < BaseEnum
        graphql_name 'ComplianceStandardsAdherenceStandard'
        description 'Name of the compliance standard.'

        ::Enums::Projects::ComplianceStandards::Adherence.standard.each_key do |standard|
          value standard.to_s.upcase, value: standard.to_s, description: standard.to_s.humanize
        end
      end
    end
  end
end
