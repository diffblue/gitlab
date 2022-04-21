# frozen_string_literal: true

FactoryBot.define do
  factory :devops_adoption_snapshot, class: 'Analytics::DevopsAdoption::Snapshot' do
    association :namespace

    recorded_at { Time.zone.now }
    end_time { 1.month.ago.end_of_month }
    issue_opened { true }
    merge_request_opened { false }
    merge_request_approved { false }
    runner_configured { true }
    pipeline_succeeded { false }
    deploy_succeeded { true }
  end
end
