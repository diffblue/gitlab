# frozen_string_literal: true

FactoryBot.define do
  factory :geo_pages_deployment_state, class: 'Geo::PagesDeploymentState' do
    pages_deployment

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
