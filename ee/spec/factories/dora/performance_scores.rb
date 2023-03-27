# frozen_string_literal: true

FactoryBot.define do
  factory :dora_performance_score, class: 'Dora::PerformanceScore' do
    project
    date { Time.current.to_date.beginning_of_month }
  end
end
