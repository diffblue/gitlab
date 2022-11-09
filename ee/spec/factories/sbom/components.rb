# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_component, class: 'Sbom::Component' do
    component_type { :library }
    purl_type { :npm }

    sequence(:name) { |n| "component-#{n}" }
  end
end
