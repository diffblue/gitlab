# frozen_string_literal: true

FactoryBot.define do
  factory :geo_design_management_repository_state, class: 'Geo::DesignManagementRepositoryState' do
    design_management_repository

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
