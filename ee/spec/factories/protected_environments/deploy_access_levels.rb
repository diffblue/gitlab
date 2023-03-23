# frozen_string_literal: true
FactoryBot.define do
  factory :protected_environment_deploy_access_level, class: 'ProtectedEnvironments::DeployAccessLevel' do
    user { nil }
    group { nil }
    protected_environment
    access_level { user_id.nil? && group_id.nil? ? Gitlab::Access::DEVELOPER : nil }

    trait :maintainer_access do
      access_level { Gitlab::Access::MAINTAINER }
    end
  end
end
