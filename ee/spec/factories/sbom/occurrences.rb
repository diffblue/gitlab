# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_occurrence, class: 'Sbom::Occurrence' do
    pipeline { association :ci_pipeline }
    project { pipeline.project }
    commit_sha { pipeline.sha }
    component_version { association :sbom_component_version }
    component { component_version.component }
    source { association :sbom_source }

    after(:build) do |occurrence|
      occurrence.uuid = Sbom::OccurrenceUUID.generate(
        project_id: occurrence.project.id,
        component_id: occurrence.component.id,
        component_version_id: occurrence.component_version.id,
        source_id: occurrence.source.id
      )
    end
  end
end
