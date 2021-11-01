# frozen_string_literal: true

FactoryBot.modify do
  factory :project_member do
    trait :awaiting do
      after(:create) do |member|
        member.wait
      end
    end
  end
end
