# frozen_string_literal: true

FactoryBot.modify do
  factory :plan_limits do
    trait :free_plan do
      plan factory: :free_plan
    end
  end
end
