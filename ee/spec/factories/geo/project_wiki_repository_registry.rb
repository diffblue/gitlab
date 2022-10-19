# frozen_string_literal: true

FactoryBot.define do
  factory :geo_project_wiki_repository_registry, class: 'Geo::ProjectWikiRepositoryRegistry' do
    project
    state { Geo::ProjectWikiRepositoryRegistry.state_value(:pending) }
  end
end
