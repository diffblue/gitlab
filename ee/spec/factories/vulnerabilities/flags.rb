# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_flag, class: 'Vulnerabilities::Flag' do
    finding factory: :vulnerabilities_finding
    origin { 'post analyzer X' }
    description { 'static string to sink' }

    trait :false_positive do
      flag_type { Vulnerabilities::Flag.flag_types[:false_positive] }
    end
  end
end
