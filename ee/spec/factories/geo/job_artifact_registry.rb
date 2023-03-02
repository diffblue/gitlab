# frozen_string_literal: true

FactoryBot.define do
  factory :geo_job_artifact_registry, class: 'Geo::JobArtifactRegistry' do
    association :job_artifact, factory: [:ci_job_artifact, :with_file]
    state { Geo::JobArtifactRegistry.state_value(:pending) }

    trait :synced do
      state { Geo::JobArtifactRegistry.state_value(:synced) }
      last_synced_at { 5.days.ago }
    end

    trait :failed do
      state { Geo::JobArtifactRegistry.state_value(:failed) }
      last_synced_at { 1.day.ago }
      retry_count { 2 }
      retry_at { 2.hours.from_now }
      last_sync_failure { 'Random error' }
    end

    trait :started do
      state { Geo::JobArtifactRegistry.state_value(:started) }
      last_synced_at { 1.day.ago }
      retry_count { 0 }
    end

    trait :verification_succeeded do
      verification_checksum { 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef' }
      verification_state { Geo::JobArtifactRegistry.verification_state_value(:verification_succeeded) }
      verified_at { 5.days.ago }
    end

    trait :orphan do
      after(:create) do |registry, _|
        Ci::JobArtifact.find(registry.artifact_id).delete
      end
    end
  end
end
