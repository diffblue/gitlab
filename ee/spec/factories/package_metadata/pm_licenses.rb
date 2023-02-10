# frozen_string_literal: true

FactoryBot.define do
  factory :pm_license, class: 'PackageMetadata::License' do
    sequence(:spdx_identifier) { |n| "OLDAP-2.#{n}" }

    initialize_with { PackageMetadata::License.find_or_initialize_by(spdx_identifier: spdx_identifier) }
  end
end
