# frozen_string_literal: true
FactoryBot.define do
  factory :protected_environment do
    name { 'production' }
    project

    transient do
      authorize_user_to_deploy { nil }
      authorize_group_to_deploy { nil }
    end

    after(:build) do |protected_environment, evaluator|
      if user = evaluator.authorize_user_to_deploy
        protected_environment.deploy_access_levels.new(user: user)
      end

      if group = evaluator.authorize_group_to_deploy
        protected_environment.deploy_access_levels.new(group: group)
      end
    end

    before(:create) do |protected_environment, evaluator|
      if protected_environment.deploy_access_levels.empty?
        protected_environment.deploy_access_levels.new(user: create(:user))
      end
    end

    trait :admins_can_deploy do
      after(:build) do |protected_environment|
        protected_environment.deploy_access_levels.new(access_level: Gitlab::Access::ADMIN)
      end
    end

    trait :maintainers_can_deploy do
      after(:build) do |protected_environment|
        protected_environment.deploy_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :developers_can_deploy do
      after(:build) do |protected_environment|
        protected_environment.deploy_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :production do
      name { 'production' }
    end

    trait :staging do
      name { 'staging' }
    end

    trait :project_level do
      project
      group { nil }
    end

    trait :group_level do
      project { nil }
      group
    end
  end
end
