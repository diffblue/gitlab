# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallRotationDateInputType < BaseInputObject
      graphql_name 'OncallRotationDateInputType'
      description 'Date input type for on-call rotation'

      argument :date, GraphQL::Types::String,
                required: true,
                description: 'The date component of the date in YYYY-MM-DD format.'

      argument :time, GraphQL::Types::String,
                required: true,
                description: 'The time component of the date in 24hr HH:MM format.'

      DATE_FORMAT = %r[^\d{4}-[0123]\d-\d{2}$].freeze
      TIME_FORMAT = %r[^(0\d|1\d|2[0-3]):[0-5]\d$].freeze

      def prepare
        raise Gitlab::Graphql::Errors::ArgumentError, 'Date given is invalid' unless DATE_FORMAT.match?(date)
        raise Gitlab::Graphql::Errors::ArgumentError, 'Time given is invalid' unless TIME_FORMAT.match?(time)

        DateTime.parse("#{date} #{time}")
      rescue ArgumentError, TypeError, Date::Error
        raise Gitlab::Graphql::Errors::ArgumentError, 'Date & time is invalid'
      end
    end
  end
end
