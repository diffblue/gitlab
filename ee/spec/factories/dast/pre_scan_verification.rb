# frozen_string_literal: true

FactoryBot.define do
  factory :dast_pre_scan_verification, class: 'Dast::PreScanVerification' do
    dast_profile
    ci_pipeline { association :ci_pipeline, project: dast_profile.project }
  end
end
