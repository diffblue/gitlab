# frozen_string_literal: true

module Resolvers
  module Analytics
    module ContributionAnalytics
      class ContributionsResolver < BaseResolver
        type Types::Analytics::ContributionAnalytics::ContributionMetadataType, null: true

        MAX_RANGE = 3.months.freeze

        argument :from, GraphQL::Types::ISO8601Date, required: true,
                                                     description: 'Start date of the reporting time range.'
        argument :to, GraphQL::Types::ISO8601Date, required: true,
                                                   description: 'End date of the reporting time range. ' \
                                                   'The end date must be within 31 days after the start date.'

        def resolve(from:, to:)
          validate_date_range!(from, to)

          data_collector = Gitlab::ContributionAnalytics::DataCollector.new(group: object, from: from, to: to)
          users = data_collector.users.sort_by(&:id)

          users.map do |user|
            { user: user }.tap do |counts_per_user|
              Gitlab::ContributionAnalytics::DataCollector::EVENT_TYPES.each do |event_type|
                counts_per_user[event_type] = data_collector.totals[event_type].fetch(user.id, 0)
              end
            end
          end
        end

        private

        def validate_date_range!(from, to)
          if (to - from).days > MAX_RANGE
            error_message = s_('ContributionAnalytics|The given date range is larger than 31 days')
            raise ::Gitlab::Graphql::Errors::ArgumentError, error_message
          end

          return unless to < from

          error_message = s_('ContributionAnalytics|The to date is earlier than the given from date')
          raise ::Gitlab::Graphql::Errors::ArgumentError, error_message
        end
      end
    end
  end
end
