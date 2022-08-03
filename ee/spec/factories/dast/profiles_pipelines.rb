# frozen_string_literal: true

FactoryBot.define do
  factory :dast_profiles_pipeline, class: 'Dast::ProfilesPipeline' do
    dast_profile

    ci_pipeline { association :ci_pipeline, project: dast_profile.project }
  end
end
