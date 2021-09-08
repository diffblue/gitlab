# frozen_string_literal: true

FactoryBot.define do
  factory :dast_site_profile_secret_variable, class: 'Dast::SiteProfileSecretVariable' do
    dast_site_profile

    sequence(:key) { |n| "VARIABLE_#{n}" }
    raw_value { 'VARIABLE_VALUE' }

    trait :password do
      key { Dast::SiteProfileSecretVariable::PASSWORD }
    end

    trait :request_headers do
      key { Dast::SiteProfileSecretVariable::REQUEST_HEADERS }
    end
  end
end
