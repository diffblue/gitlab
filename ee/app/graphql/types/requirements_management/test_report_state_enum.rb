# frozen_string_literal: true

module Types
  module RequirementsManagement
    class TestReportStateEnum < BaseEnum
      graphql_name 'TestReportState'
      description 'State of a test report'

      value 'PASSED', value: 'passed', description: 'Passed test report.'
      value 'FAILED', value: 'failed', description: 'Failed test report.'
    end
  end
end
