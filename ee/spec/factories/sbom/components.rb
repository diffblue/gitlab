# frozen_string_literal: true

FactoryBot.define do
  factory :sbom_component, class: 'Sbom::Component' do
    component_type { :library }
    purl_type { :npm }

    sequence(:name) { |n| "component-#{n}" }

    trait :bundler do
      name { "bundler" }
      purl_type { :gem }
    end

    trait :caddy do
      name { "caddy" }
      purl_type { :golang }
    end

    trait :webpack do
      name { "webpack" }
      purl_type { :npm }
    end
  end
end
