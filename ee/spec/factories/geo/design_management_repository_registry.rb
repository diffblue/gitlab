# frozen_string_literal: true

FactoryBot.define do
  factory :geo_design_management_repository_registry, class: 'Geo::DesignManagementRepositoryRegistry' do
    design_management_repository # This association should have data, like a file or repository
    state { Geo::DesignManagementRepositoryRegistry.state_value(:pending) }

    trait :synced do
      state { Geo::DesignManagementRepositoryRegistry.state_value(:synced) }
      last_synced_at { 5.days.ago }
    end

    trait :failed do
      state { Geo::DesignManagementRepositoryRegistry.state_value(:failed) }
      last_synced_at { 1.day.ago }
      retry_count { 2 }
      retry_at { 2.hours.from_now }
      last_sync_failure { 'Random error' }
    end

    trait :started do
      state { Geo::DesignManagementRepositoryRegistry.state_value(:started) }
      last_synced_at { 1.day.ago }
      retry_count { 0 }
    end

    trait :verification_succeeded do
      verification_checksum { 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef' }
      verification_state { Geo::DesignManagementRepositoryRegistry.verification_state_value(:verification_succeeded) }
      verified_at { 5.days.ago }
    end
  end
end
