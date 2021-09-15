# frozen_string_literal: true

module Types
  class SecurityScannerTypeEnum < BaseEnum
    graphql_name 'SecurityScannerType'
    description 'The type of the security scanner'

    ::Security::SecurityJobsFinder.allowed_job_types.each do |scanner|
      upcase_type = scanner.upcase.to_s
      human_type = case scanner
                   when :dast, :sast then upcase_type
                   when :api_fuzzing then 'API Fuzzing'
                   else scanner.to_s.titleize
                   end

      value upcase_type, description: "#{human_type} scanner"
    end
  end
end
