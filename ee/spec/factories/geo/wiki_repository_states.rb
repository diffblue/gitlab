# frozen_string_literal: true

FactoryBot.define do
  factory :geo_wiki_repository_state, class: 'Geo::WikiRepositoryState' do
    project_wiki_repository

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
