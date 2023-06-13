# frozen_string_literal: true

FactoryBot.define do
  factory :geo_job_artifact_state, class: 'Geo::JobArtifactState' do
    job_artifact factory: :ci_job_artifact

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
