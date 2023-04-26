# frozen_string_literal: true

FactoryBot.modify do
  factory :project do
    trait :import_hard_failed do
      import_status { :failed }

      after(:create) do |project, evaluator|
        project.import_state.update!(
          retry_count: Gitlab::Mirror::MAX_RETRY + 1,
          last_update_at: Time.now - 1.minute
        )
      end
    end

    trait :mirror do
      mirror { true }
      import_url { generate(:url) }
      mirror_user_id { creator_id }
    end

    trait :random_last_repository_updated_at do
      last_repository_updated_at { rand(1.year).seconds.ago }
    end

    trait :github_imported do
      import_type { 'github' }
    end

    trait :with_vulnerability do
      after(:create) do |project|
        create(:vulnerability, :detected, project: project)
      end
    end

    trait :with_vulnerabilities do
      after(:create) do |project|
        create_list(:vulnerability, 2, :with_finding, :detected, project: project)
      end
    end

    trait :with_security_scans do
      after(:create) do |project|
        create_list(:security_scan, 2, project: project)
      end
    end

    trait :with_compliance_framework do
      association :compliance_framework_setting, factory: :compliance_framework_project_setting
    end

    trait :with_sox_compliance_framework do
      association :compliance_framework_setting, :sox, factory: :compliance_framework_project_setting
    end

    trait :with_cve_request do
      transient do
        cve_request_enabled { true }
      end
      after(:create) do |project, evaluator|
        project.project_setting.cve_id_request_enabled = evaluator.cve_request_enabled
        project.project_setting.save!
      end
    end

    trait :with_security_orchestration_policy_configuration do
      association :security_orchestration_policy_configuration, factory: :security_orchestration_policy_configuration
    end

    trait :with_ci_minutes do
      transient do
        amount_used { 0 }
        shared_runners_duration { 0 }
      end

      after(:create) do |project, evaluator|
        if evaluator.amount_used || evaluator.shared_runners_duration
          create(
            :ci_project_monthly_usage,
            project: project, amount_used: evaluator.amount_used,
            shared_runners_duration: evaluator.shared_runners_duration
          )
        end
      end
    end

    trait :with_product_analytics_dashboard do
      repository

      after(:create) do |project|
        project.repository.create_file(
          project.creator,
          '.gitlab/analytics/dashboards/dashboard_example_1/dashboard_example_1.yaml',
          File.open(Rails.root.join('ee/spec/fixtures/product_analytics/dashboard_example_1.yaml')).read,
          message: 'test',
          branch_name: 'master'
        )

        project.repository.create_file(
          project.creator,
          '.gitlab/analytics/dashboards/visualizations/cube_line_chart.yaml',
          File.open(Rails.root.join('ee/spec/fixtures/product_analytics/cube_line_chart.yaml')).read,
          message: 'test',
          branch_name: 'master'
        )
      end
    end

    trait :with_product_analytics_funnel do
      repository

      after(:create) do |project|
        project.repository.create_file(
          project.creator,
          '.gitlab/analytics/funnels/funnel_example_1.yaml',
          File.open(Rails.root.join('ee/spec/fixtures/product_analytics/funnel_example_1.yaml')).read,
          message: 'Add funnel definition',
          branch_name: 'master'
        )
      end
    end

    trait(:allow_pipeline_trigger_approve_deployment) { allow_pipeline_trigger_approve_deployment { true } }
  end
end
