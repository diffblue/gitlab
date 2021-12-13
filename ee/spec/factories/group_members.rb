# frozen_string_literal: true

FactoryBot.modify do
  factory :group_member do
    trait :awaiting do
      after(:create) do |member|
        member.wait
      end
    end
  end
end
