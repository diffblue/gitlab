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

    trait :enterprise_user_created_via_saml do
      after(:create) do |user, evaluator|
        group_saml_identity = create(:group_saml_identity, user: user)
        user.user_detail.update!(provisioned_by_group_id: group_saml_identity.saml_provider.group_id)
      end
    end

    trait :enterprise_user_created_via_scim do
      after(:create) do |user, evaluator|
        scim_identity = create(:scim_identity, user: user)
        user.user_detail.update!(provisioned_by_group_id: scim_identity.group_id)
      end
    end

    trait :enterprise_user_based_on_domain_verification do
      provisioned_by_group_id { create(:group).id }
      provisioned_by_group_at { Time.current }
    end

    trait :service_user do
      user_type { :service_user }
    end

    trait :arkose_verified do
      after(:create) do |user|
        create(:user_custom_attribute,
          key: UserCustomAttribute::ARKOSE_RISK_BAND, value: Arkose::VerifyResponse::RISK_BAND_LOW, user: user
        )
      end
    end
  end

  factory :omniauth_user do
    transient do
      saml_provider { nil }
    end

    trait :arkose_verified do
      after(:create) do |user|
        create(:user_custom_attribute,
          key: UserCustomAttribute::ARKOSE_RISK_BAND, value: Arkose::VerifyResponse::RISK_BAND_LOW, user: user
        )
      end
    end
  end
end

FactoryBot.define do
  factory :auditor, parent: :user, traits: [:auditor]
  factory :external_user, parent: :user, traits: [:external]
end
