# frozen_string_literal: true

FactoryBot.define do
  factory :pm_license, class: 'PackageMetadata::License' do
    sequence(:spdx_identifier) { |n| "OLDAP-2.#{n}" }

    initialize_with { PackageMetadata::License.find_or_initialize_by(spdx_identifier: spdx_identifier) }

    trait :with_software_license do
      after(:create) do |license|
        name =
          case license.spdx_identifier
          when /OLDAP-*/
            "Open LDAP Public License v#{license.spdx_identifier.split('-')[-1]}"
          when 'BSD'
            'BSD-4-Clause'
          when 'Apache-2.0'
            'Apache 2.0 License'
          when 'DEFAULT-2.1'
            'Default License 2.1'
          else
            license.spdx_identifier
          end

        # rubocop: disable RSpec/FactoryBot/StrategyInCallback
        SoftwareLicense.where(spdx_identifier: license.spdx_identifier, name: name).first_or_create!
        # rubocop: enable RSpec/FactoryBot/StrategyInCallback
      end
    end
  end
end
