# frozen_string_literal: true

FactoryBot.define do
  factory :security_training_provider, class: 'Security::TrainingProvider' do
    sequence(:name) { |n| "Training Provider ##{n}" }
    url { 'https://example.com' }
  end
end
