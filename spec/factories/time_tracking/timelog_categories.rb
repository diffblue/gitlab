# frozen_string_literal: true

FactoryBot.define do
  factory :timelog_category, class: 'TimeTracking::TimelogCategory' do
    group

    name { generate(:name) }
  end
end
