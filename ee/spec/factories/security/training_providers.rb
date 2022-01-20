# frozen_string_literal: true

FactoryBot.define do
  factory :security_training_provider, class: 'Security::TrainingProvider' do
    name { 'Acme' }
    url { 'example.com' }
  end
end
