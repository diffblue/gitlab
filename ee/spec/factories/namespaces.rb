# frozen_string_literal: true

FactoryBot.modify do
  factory :namespace do
    trait :with_ci_minutes do
      transient do
        ci_minutes_limit { 500 }
        ci_minutes_used { 400 }
      end

      after(:build) do |namespace, evaluator|
        namespace.shared_runners_minutes_limit = evaluator.ci_minutes_limit
      end

      after(:create) do |namespace, evaluator|
        if evaluator.ci_minutes_used
          create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: evaluator.ci_minutes_used)

          create(:namespace_statistics,
            namespace: namespace,
            shared_runners_seconds: evaluator.ci_minutes_used.minutes,
            shared_runners_seconds_last_reset: Time.current)
        end
      end
    end

    trait :with_not_used_build_minutes_limit do
      namespace_statistics factory: :namespace_statistics, shared_runners_seconds: 300.minutes.to_i
      shared_runners_minutes_limit { 500 }

      after(:create) do |namespace, evaluator|
        create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 300)
      end
    end

    trait :with_used_build_minutes_limit do
      namespace_statistics factory: :namespace_statistics, shared_runners_seconds: 1000.minutes.to_i
      shared_runners_minutes_limit { 500 }

      after(:create) do |namespace, evaluator|
        create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 1000)
      end
    end

    trait :with_security_orchestration_policy_configuration do
      association :security_orchestration_policy_configuration, factory: [:security_orchestration_policy_configuration, :namespace]
    end
  end
end

FactoryBot.define do
  factory :namespace_with_plan, parent: :namespace do
    transient do
      plan { :free_plan }
      trial_ends_on { nil }
    end

    after(:create) do |namespace, evaluator|
      if evaluator.plan
        create(:namespace_settings, namespace: namespace)

        create(
          :gitlab_subscription,
          namespace: namespace,
          hosted_plan: create(evaluator.plan),
          trial: evaluator.trial_ends_on.present?,
          trial_ends_on: evaluator.trial_ends_on
        )
      end
    end
  end
end
