# frozen_string_literal: true

FactoryBot.define do
  factory :security_training, class: 'Security::Training' do
    project
    provider factory: :security_training_provider

    trait :primary do
      is_primary { true }
    end
  end
end
