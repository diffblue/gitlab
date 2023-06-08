# frozen_string_literal: true

module Types
  module Security
    class ComparableReportTypeEnum < BaseEnum
      graphql_name 'ComparableSecurityReportType'
      description 'Comparable security report type'

      ::Security::MergeRequestSecurityReportGenerationService::ALLOWED_REPORT_TYPES.each do |report_type|
        human_type = case report_type.to_sym
                     when :dast, :sast then report_type.upcase
                     when :api_fuzzing then 'API Fuzzing'
                     else report_type.titleize
                     end

        value report_type.upcase, value: report_type, description: "#{human_type} report"
      end
    end
  end
end
