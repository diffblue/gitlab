# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationSeverityEnum < BaseEnum
        graphql_name 'ComplianceViolationSeverity'
        description 'Severity of the compliance violation.'

        ::Enums::MergeRequests::ComplianceViolation.severity_levels.keys.each do |severity|
          value severity.to_s.upcase, value: severity.to_s, description: "#{severity.to_s.humanize} severity"
        end
      end
    end
  end
end
