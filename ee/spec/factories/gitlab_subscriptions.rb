# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_subscription do
    namespace
    association :hosted_plan, factory: :ultimate_plan
    seats { 10 }
    start_date { Date.current }
    end_date { Date.current.advance(years: 1) }
    trial { false }

    trait :expired do
      start_date { Date.current.advance(years: -1, months: -1) }
      end_date { Date.current.advance(months: -1) }
    end

    trait :active_trial do
      trial { true }
      trial_starts_on { Date.current.advance(days: -15) }
      trial_ends_on { Date.current.advance(days: 15) }
    end

    trait :extended_trial do
      active_trial
      trial_extension_type { GitlabSubscription.trial_extension_types[:extended] }
    end

    trait :expired_trial do
      trial { true }
      trial_starts_on { Date.current.advance(days: -31) }
      trial_ends_on { Date.current.advance(days: -1) }
    end

    trait :reactivated_trial do
      expired_trial
      trial_extension_type { GitlabSubscription.trial_extension_types[:reactivated] }
    end

    trait :default do
      association :hosted_plan, factory: :default_plan
    end

    trait :free do
      hosted_plan_id { nil }
    end

    trait :bronze do
      association :hosted_plan, factory: :bronze_plan
    end

    trait :silver do
      association :hosted_plan, factory: :silver_plan
    end

    trait :premium do
      association :hosted_plan, factory: :premium_plan
    end

    trait :gold do
      association :hosted_plan, factory: :gold_plan
    end

    trait :ultimate do
      association :hosted_plan, factory: :ultimate_plan
    end

    trait :premium_trial do
      association :hosted_plan, factory: :premium_trial_plan
    end

    trait :ultimate_trial do
      association :hosted_plan, factory: :ultimate_trial_plan
    end
  end
end
