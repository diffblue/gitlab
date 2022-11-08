# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profile_schedule_input_type, class: 'Types::Dast::ProfileScheduleInputType' do
    skip_create

    initialize_with do
      context = GraphQL::Query::Context.new(
        query: GraphQL::Query.new(GitlabSchema, document: nil, context: {}, variables: {}),
        values: {},
        object: nil
      )

      arguments = {
        active: true,
        timezone: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.identifier }.sample,
        startsAt: Time.now,
        cadence: { unit: %w(day month year week).sample, duration: 1 }
      }

      ruby_kwargs = arguments.transform_keys { |key| key.to_s.underscore.to_sym }

      ::Types::Dast::ProfileScheduleInputType.new(ruby_kwargs: ruby_kwargs, defaults_used: [], context: context)
    end
  end
end
