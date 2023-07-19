# frozen_string_literal: true

module Types
  module Projects
    module ComplianceStandards
      class AdherenceCheckNameEnum < BaseEnum
        graphql_name 'ComplianceStandardsAdherenceCheckName'
        description 'Name of the check for the compliance standard.'

        ::Enums::Projects::ComplianceStandards::Adherence.check_name.each_key do |check|
          value check.to_s.upcase, value: check.to_s, description: check.to_s.humanize
        end
      end
    end
  end
end
