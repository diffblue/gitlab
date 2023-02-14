# frozen_string_literal: true

FactoryBot.define do
  factory :automation_rule, class: 'Automation::Rule' do
    namespace

    name { generate(:name) }
    rule { '-' }
  end
end
