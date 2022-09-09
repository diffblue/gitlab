# frozen_string_literal: true

FactoryBot.define do
  factory :dora_configuration, class: 'Dora::Configuration' do
    project
    branches_for_lead_time_for_changes { %w[master main] }
  end
end
