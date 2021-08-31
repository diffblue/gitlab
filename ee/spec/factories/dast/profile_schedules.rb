# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profile_schedule, class: 'Dast::ProfileSchedule' do
    project
    dast_profile
    owner { association(:user) }
    timezone { FFaker::Address.time_zone }
    starts_at { Time.now }
    cadence { { unit: %w(day month year week).sample, duration: 1 } }
  end
end
