# frozen_string_literal: true

FactoryBot.define do
  factory :deployment_approval, class: 'Deployments::Approval' do
    user
    deployment
    status { 'approved' }

    trait :rejected do
      status { 'rejected' }
    end
  end
end
