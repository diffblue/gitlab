# frozen_string_literal: true

module Types
  module Security
    module FindingReportsComparer
      class StatusEnum < BaseEnum
        graphql_name 'FindingReportsComparerStatus'
        description 'Report comparison status'

        value 'PARSED', value: :parsed, description: "Report was generated."
        value 'PARSING', value: :parsing, description: "Report is being generated."
        value 'ERROR', value: :error, description: "An error happened while generating the report."
      end
    end
  end
end
