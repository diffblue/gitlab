# frozen_string_literal: true
FactoryBot.define do
  factory :protected_environment do
    name { 'production' }
    project

    transient do
      authorize_user_to_deploy { nil }
      authorize_group_to_deploy { nil }
      require_users_to_approve { [] }
    end

    after(:build) do |protected_environment, evaluator|
      if deploy_user = evaluator.authorize_user_to_deploy
        protected_environment.deploy_access_levels.new(user: deploy_user)
      end

      if deploy_group = evaluator.authorize_group_to_deploy
        protected_environment.deploy_access_levels.new(group: deploy_group)
      end

      if (approve_users = evaluator.require_users_to_approve).present?
        approve_users.each do |approve_user|
          protected_environment.approval_rules.new(user_id: approve_user.id, required_approvals: 1)
        end
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

    trait :maintainers_can_approve do
      after(:build) do |protected_environment|
        protected_environment.approval_rules.new(access_level: Gitlab::Access::MAINTAINER, required_approvals: 1)
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
