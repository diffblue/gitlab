# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profile_schedule_input_type, class: 'Types::Dast::ProfileScheduleInputType' do
    context = GraphQL::Query::Context.new(
      query: GraphQL::Query.new(GitlabSchema, document: nil, context: {}, variables: {}),
      values: {},
      object: nil
    )
    skip_create

    arguments = {
      active: true,
      timezone: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.identifier }.sample,
      startsAt: Time.now,
      cadence: { unit: %w(day month year week).sample, duration: 1 }
    }
    ::Types::Dast::ProfileScheduleInputType.to_graphql

    initialize_with { ::Types::Dast::ProfileScheduleInputType.new(arguments, defaults_used: [], context: context) }
  end
end
