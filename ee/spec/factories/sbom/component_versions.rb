# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_component_version, class: 'Sbom::ComponentVersion' do
    component { association :sbom_component }

    sequence(:version) { |n| "v0.0.#{n}" }
  end
end
