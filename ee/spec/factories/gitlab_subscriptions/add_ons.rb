# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_subscription_add_on, class: 'GitlabSubscriptions::AddOn' do
    name { GitlabSubscriptions::AddOn.names[:code_suggestions] }
    description { 'AddOn for code suggestion features' }

    trait :code_suggestions do
      name { GitlabSubscriptions::AddOn.names[:code_suggestions] }
    end
  end
end
