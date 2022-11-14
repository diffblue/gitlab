# frozen_string_literal: true

FactoryBot.define do
  factory :geo_project_wiki_repository_state, class: 'Geo::ProjectWikiRepositoryState' do
    project
    project_wiki_repository { association(:project_wiki_repository, project: project) }

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
