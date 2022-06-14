# frozen_string_literal: true

FactoryBot.modify do
  factory :user_namespace do
    trait :user_namespace_with_plan do
      transient do
        plan { :free_plan }
        trial_ends_on { nil }
      end

      after(:create) do |user_namespace, evaluator|
        if evaluator.plan
          create(:namespace_settings, namespace: user_namespace)

          create(:gitlab_subscription,
                 namespace: user_namespace,
                 hosted_plan: create(evaluator.plan),
                 trial: evaluator.trial_ends_on.present?,
                 trial_ends_on: evaluator.trial_ends_on)
        end
      end
    end
  end
end
