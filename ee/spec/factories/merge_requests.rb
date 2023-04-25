# frozen_string_literal: true

FactoryBot.modify do
  factory :merge_request do
    trait :with_approver do
      after :create do |merge_request|
        create :approver, target: merge_request
      end
    end

    trait :blocked do
      after :create do |merge_request, _|
        create(:merge_request_block, blocked_merge_request: merge_request)
      end
    end

    trait :on_train do
      transient do
        train_creator { author }
        status { 'idle' }
      end

      auto_merge_enabled { true }
      auto_merge_strategy { AutoMergeService::STRATEGY_MERGE_TRAIN }
      merge_user { train_creator }

      after :create do |merge_request, evaluator|
        merge_request.create_merge_train_car(
          status: evaluator.status,
          user: evaluator.train_creator,
          target_project: merge_request.target_project,
          target_branch: merge_request.target_branch
        )
      end
    end

    trait :with_merge_train_pipeline do
      with_merge_request_pipeline

      after(:create) do |merge_request, evaluator|
        merge_request.pipelines_for_merge_request.last
          .update!(ref: merge_request.train_ref_path)
      end
    end

    trait :add_to_merge_train_when_pipeline_succeeds do
      auto_merge_enabled { true }
      auto_merge_strategy { AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS }
      merge_user { author }
    end

    trait :with_productivity_metrics do
      transient do
        metrics_data { {} }
      end

      after :build do |mr, evaluator|
        next if evaluator.metrics_data.empty?

        mr.build_metrics unless mr.metrics
        mr.metrics.assign_attributes evaluator.metrics_data
      end
    end

    transient do
      approval_groups { [] }
      approval_users { [] }
    end

    after :create do |merge_request, evaluator|
      next if evaluator.approval_users.blank? && evaluator.approval_groups.blank?

      rule = merge_request.approval_rules.first_or_create!(attributes_for(:approval_merge_request_rule))
      rule.users = evaluator.approval_users if evaluator.approval_users.present?
      rule.groups = evaluator.approval_groups if evaluator.approval_groups.present?
    end
  end
end

FactoryBot.define do
  factory :merge_request_with_approver, parent: :merge_request, traits: [:with_approver]

  factory :ee_merge_request, parent: :merge_request do
    trait :with_license_scanning_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_license_scanning_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_container_scanning_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_container_scanning_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_dependency_scanning_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_dependency_scanning_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_coverage_fuzzing_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_coverage_fuzzing_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_api_fuzzing_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_api_fuzzing_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_dast_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_dast_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_metrics_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_metrics_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end

    trait :with_cyclonedx_reports do
      after(:build) do |merge_request|
        merge_request.head_pipeline = build(
          :ee_ci_pipeline,
          :success,
          :with_cyclonedx_report,
          project: merge_request.source_project,
          ref: merge_request.source_branch,
          sha: merge_request.diff_head_sha)
      end
    end
  end
end
