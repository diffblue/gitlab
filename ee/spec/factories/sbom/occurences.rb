# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_occurrence, class: 'Sbom::Occurrence' do
    project
    component_version { association :sbom_component_version }
    component { component_version.component }
    pipeline { association :ci_pipeline }
    source { association :sbom_source }

    commit_sha { pipeline&.sha || 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
  end
end
