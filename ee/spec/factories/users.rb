# frozen_string_literal: true

FactoryBot.modify do
  factory :user do
    trait :auditor do
      auditor { true }
    end

    trait :group_managed do
      association :managing_group, factory: :group_with_managed_accounts

      after(:create) do |user, evaluator|
        create(:group_saml_identity,
          user: user,
          saml_provider: user.managing_group.saml_provider
        )
      end
    end

    trait :service_user do
      user_type { :service_user }
    end

    trait :arkose_verified do
      after(:create) do |user|
        create(:user_custom_attribute, key: 'arkose_risk_band', value: 'Low', user: user)
      end
    end
  end

  factory :omniauth_user do
    transient do
      saml_provider { nil }
    end

    trait :arkose_verified do
      after(:create) do |user|
        create(:user_custom_attribute, key: 'arkose_risk_band', value: 'Low', user: user)
      end
    end
  end
end

FactoryBot.define do
  factory :auditor, parent: :user, traits: [:auditor]
  factory :external_user, parent: :user, traits: [:external]
end
