# frozen_string_literal: true

FactoryBot.define do
  factory :geo_project_state, class: 'Geo::ProjectState' do
    project

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
