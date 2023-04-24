# frozen_string_literal: true

FactoryBot.modify do
  factory :protected_branch do
    transient do
      ee { true }
      authorize_user_to_push { nil }
      authorize_user_to_merge { nil }
      authorize_user_to_unprotect { nil }
      authorize_group_to_push { nil }
      authorize_group_to_merge { nil }
      authorize_group_to_unprotect { nil }
    end

    trait :user_can_merge do
      authorize_user_to_merge do
        association(:user, maintainer_projects: [project])
      end
    end

    trait :group_can_merge do
      authorize_group_to_merge do
        group || project.group || association(:project_group_link, project: project).group
      end
    end

    trait :user_can_push do
      authorize_user_to_push do
        association(:user, maintainer_projects: [project])
      end
    end

    trait :group_can_push do
      authorize_group_to_push do
        group || project.group || association(:project_group_link, project: project).group
      end
    end

    trait :developers_can_unprotect do
      after(:build) do |protected_branch, evaluator|
        protected_branch.unprotect_access_levels.new(access_level: Gitlab::Access::DEVELOPER)
      end
    end

    trait :maintainers_can_unprotect do
      after(:build) do |protected_branch, evaluator|
        protected_branch.unprotect_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end
    end

    trait :user_can_unprotect do
      authorize_user_to_unprotect do
        association(:user, maintainer_projects: [project])
      end
    end

    trait :group_can_unprotect do
      authorize_group_to_unprotect do
        group || project.group || association(:project_group_link, project: project).group
      end
    end

    after(:build) do |protected_branch, evaluator|
      push_user = evaluator.authorize_user_to_push
      push_group = evaluator.authorize_group_to_push
      merge_user = evaluator.authorize_user_to_merge
      merge_group = evaluator.authorize_group_to_merge
      unprotect_user = evaluator.authorize_user_to_unprotect
      unprotect_group = evaluator.authorize_group_to_unprotect

      protected_branch.push_access_levels.new(user: push_user) if push_user
      protected_branch.merge_access_levels.new(user: merge_user) if merge_user
      protected_branch.unprotect_access_levels.new(user: unprotect_user) if unprotect_user
      protected_branch.push_access_levels.new(group: push_group) if push_group
      protected_branch.merge_access_levels.new(group: merge_group) if merge_group
      protected_branch.unprotect_access_levels.new(group: unprotect_group) if unprotect_group

      next if !evaluator.default_access_level || [:merge, :push, :unprotect].any? do |action|
        protected_branch.public_send("#{action}_access_levels").present?
      end

      if evaluator.default_merge_level
        protected_branch.merge_access_levels.new(access_level: Gitlab::Access::MAINTAINER)
      end

      protected_branch.push_access_levels.new(access_level: Gitlab::Access::MAINTAINER) if evaluator.default_push_level
    end
  end
end
