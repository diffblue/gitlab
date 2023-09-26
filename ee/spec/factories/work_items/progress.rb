# frozen_string_literal: true
FactoryBot.define do
  factory :progress, class: 'WorkItems::Progress' do
    progress { 20 }
    association :work_item, :objective
    reminder_frequency { :never }
  end
end
