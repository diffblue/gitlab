# frozen_string_literal: true

FactoryBot.modify do
  factory :group do
    after(:create) do |group, evaluator|
      create(:namespace_settings, namespace: group) unless group.namespace_settings
      create(:namespace_ci_cd_settings, namespace: group) unless group.ci_cd_settings
    end

    trait :wiki_repo do
      after(:create) do |group|
        stub_feature_flags(main_branch_over_master: false)

        raise 'Failed to create wiki repository!' unless group.create_wiki
      end
    end
  end
end

FactoryBot.define do
  factory :group_with_members, parent: :group do
    after(:create) do |group, evaluator|
      group.add_developer(create(:user))
    end
  end

  factory :group_with_ldap, parent: :group do
    transient do
      cn { 'group1' }
      group_access { Gitlab::Access::GUEST }
      provider { 'ldapmain' }
    end

    factory :group_with_ldap_group_link do
      after(:create) do |group, evaluator|
        group.ldap_group_links << create(
          :ldap_group_link,
          cn: evaluator.cn,
          group_access: evaluator.group_access,
          provider: evaluator.provider
        )
      end
    end

    factory :group_with_ldap_group_filter_link do
      after(:create) do |group, evaluator|
        group.ldap_group_links << create(
          :ldap_group_link,
          filter: '(a=b)',
          cn: nil,
          group_access: evaluator.group_access,
          provider: evaluator.provider
        )
      end
    end
  end

  factory :group_with_deletion_schedule, parent: :group do
    transient do
      deleting_user { association(:user) }
      marked_for_deletion_on { Date.current }
    end

    after(:create) do |group, evaluator|
      create(:group_deletion_schedule,
        group: group,
        deleting_user: evaluator.deleting_user,
        marked_for_deletion_on: evaluator.marked_for_deletion_on
      )
    end
  end

  factory :group_with_managed_accounts, parent: :group do
    after(:create) do |group, evaluator|
      create(:saml_provider,
        :enforced_group_managed_accounts,
        group: group)
    end
  end

  factory :group_with_plan, parent: :group do
    transient do
      plan { :free_plan }
      trial_ends_on { nil }
    end

    after(:create) do |group, evaluator|
      if evaluator.plan
        create(
          :gitlab_subscription,
          namespace: group,
          hosted_plan: create(evaluator.plan),
          trial: evaluator.trial_ends_on.present?,
          trial_ends_on: evaluator.trial_ends_on
        )
      end
    end
  end
end
