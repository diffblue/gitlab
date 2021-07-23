# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class OncallRotationActivePeriodType < BaseObject
      graphql_name 'OncallRotationActivePeriodType'
      description 'Active period time range for on-call rotation'

      field :start_time, GraphQL::Types::String,
            null: true,
            description: 'The start of the rotation active period.'

      field :end_time, GraphQL::Types::String,
            null: true,
            description: 'The end of the rotation active period.'

      alias_method :active_period, :object

      def start_time
        active_period.start_time&.strftime('%H:%M')
      end

      def end_time
        active_period.end_time&.strftime('%H:%M')
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
