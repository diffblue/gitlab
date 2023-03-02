# frozen_string_literal: true

FactoryBot.define do
  factory :geo_group_wiki_repository_registry, class: 'Geo::GroupWikiRepositoryRegistry' do
    group_wiki_repository
    state { Geo::GroupWikiRepositoryRegistry.state_value(:pending) }

    trait :synced do
      state { Geo::GroupWikiRepositoryRegistry.state_value(:synced) }
      last_synced_at { 5.days.ago }
    end

    trait :failed do
      state { Geo::GroupWikiRepositoryRegistry.state_value(:failed) }
      last_synced_at { 1.day.ago }
      retry_count { 2 }
      retry_at { 2.hours.from_now }
      last_sync_failure { 'Random error' }
    end

    trait :started do
      state { Geo::GroupWikiRepositoryRegistry.state_value(:started) }
      last_synced_at { 1.day.ago }
      retry_count { 0 }
    end
  end
end
