# frozen_string_literal: true

FactoryBot.define do
  factory :issuable_sla do
    issue
    due_at { 1.hour.from_now }

    trait :exceeded do
      due_at { 1.hour.ago }
    end

    trait :label_applied do
      label_applied { true }
    end

    trait :issuable_closed do
      issuable_closed { true }
    end
  end
end
