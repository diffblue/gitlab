# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_license, class: "Gitlab::License" do
    skip_create

    trait :trial do
      block_changes_at { nil }
      restrictions do
        { trial: true }
      end
    end

    trait :expired do
      expires_at { 3.weeks.ago.to_date }
    end

    trait :cloud do
      cloud_licensing_enabled { true }
    end

    trait :offline_enabled do
      offline_cloud_licensing_enabled { true }
    end

    trait :offline_disabled do
      offline_cloud_licensing_enabled { false }
    end

    transient do
      plan { License::STARTER_PLAN }
    end

    starts_at { Date.new(1970, 1, 1) }
    expires_at { Date.current + 11.months }
    block_changes_at { expires_at ? expires_at + 2.weeks : nil }
    notify_users_at  { expires_at }
    notify_admins_at { expires_at }

    licensee do
      {
         "Name" => generate(:name),
         "Email" => generate(:email),
         "Company" => "Company name"
      }
    end

    restrictions do
      {
        add_ons: {
          'GitLab_FileLocks' => 1,
          'GitLab_Auditor_User' => 1
        },
        plan: plan,
        subscription_id: '0000'
      }
    end
  end

  factory :license do
    transient do
      plan { nil }
      expired { false }
      trial { false }
    end

    data do
      attrs = [:gitlab_license]
      attrs << :trial if trial
      attrs << :expired if expired
      attrs << :cloud if cloud

      build(*attrs, plan: plan).export
    end

    # Disable validations when creating an expired license key
    to_create { |instance| instance.save!(validate: !expired) }
  end
end
