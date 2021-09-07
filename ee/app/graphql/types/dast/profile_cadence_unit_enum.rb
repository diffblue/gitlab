# frozen_string_literal: true

module Types
  module Dast
    class ProfileCadenceUnitEnum < BaseEnum
      graphql_name 'DastProfileCadenceUnit'
      description 'Unit for the duration of Dast Profile Cadence.'

      value 'DAY', value: 'day', description: 'DAST Profile Cadence duration in days.'
      value 'WEEK', value: 'week', description: 'DAST Profile Cadence duration in weeks.'
      value 'MONTH', value: 'month', description: 'DAST Profile Cadence duration in months.'
      value 'YEAR', value: 'year', description: 'DAST Profile Cadence duration in years.'
    end
  end
end
