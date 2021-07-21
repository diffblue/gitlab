# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profile_schedule, class: 'Dast::ProfileSchedule' do
    project
    dast_profile
    owner { association(:user) }
    cron { '*/10 * * * *' }
    next_run_at { Time.now }
  end
end
