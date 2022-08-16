# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerable_component_version, class: 'Sbom::VulnerableComponentVersion' do
    component_version { association :sbom_component_version }
    advisory { association :vulnerability_advisory }
  end
end
