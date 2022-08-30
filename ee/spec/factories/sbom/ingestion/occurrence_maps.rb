# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_occurrence_map, class: '::Sbom::Ingestion::OccurrenceMap' do
    report_component factory: :ci_reports_sbom_component
    report_source factory: :ci_reports_sbom_source

    trait :with_component do
      component factory: :sbom_component
    end

    trait :with_component_version do
      component_version factory: :sbom_component_version
    end

    trait :with_source do
      source factory: :sbom_source
    end

    trait :for_occurrence_ingestion do
      with_component
      with_component_version
      with_source
    end

    skip_create

    initialize_with do
      ::Sbom::Ingestion::OccurrenceMap.new(*attributes.values_at(:report_component, :report_source)).tap do |object|
        object.component_id = attributes[:component]&.id
        object.component_version_id = attributes[:component_version]&.id
        object.source_id = attributes[:source]&.id
      end
    end
  end
end
