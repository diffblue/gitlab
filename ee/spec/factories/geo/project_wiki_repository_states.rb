# frozen_string_literal: true

FactoryBot.define do
  factory :geo_project_wiki_repository_state, class: 'Geo::ProjectWikiRepositoryState' do
    project
  end
end
