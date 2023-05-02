# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesCountPerDayResolver < VulnerabilitiesBaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::VulnerabilitiesCountByDayType, null: true
    authorize :read_security_resource
    authorizes_object!

    argument :start_date, GraphQL::Types::ISO8601Date,
      required: true,
      description: 'First day for which to fetch vulnerability history.'

    argument :end_date, GraphQL::Types::ISO8601Date,
      required: true,
      description: 'Last day for which to fetch vulnerability history.'

    def resolve(**args)
      return [] unless vulnerable

      vulnerable
        .vulnerability_historical_statistics
        .grouped_by_date
        .aggregated_by_date
        .between_dates(args[:start_date], args[:end_date])
        .index_by(&:date)
        .then { |calendar_entries| generate_missing_dates(calendar_entries, args[:start_date], args[:end_date]) }
    end

    private

    def generate_missing_dates(calendar_entries, start_date, end_date)
      severities = ::Enums::Vulnerability.severity_levels.keys
      (start_date..end_date)
        .each_with_object({}) { |date, result| result[date] = build_calendar_entry(date, calendar_entries[date], result[date - 1.day]) }
        .values
        .map { |calendar_entry| calendar_entry.attributes.slice('date', 'total', *severities) }
    end

    def build_calendar_entry(date, result_from_current_day, result_from_previous_day)
      result_from_current_day || build_missing_calendar_entry(date, result_from_previous_day)
    end

    def build_missing_calendar_entry(date, result_from_previous_day)
      ::Vulnerabilities::HistoricalStatistic.new(result_from_previous_day&.attributes.to_h.merge(date: date))
    end
  end
end
