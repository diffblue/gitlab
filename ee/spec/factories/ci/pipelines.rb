# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_pipeline, class: 'Ci::Pipeline', parent: :ci_pipeline do
    %i[api_fuzzing browser_performance codequality container_scanning cluster_image_scanning coverage_fuzzing dast dependency_list dependency_scanning license_scanning load_performance sast secret_detection].each do |report_type|
      trait "with_#{report_type}_report".to_sym do
        status { :success }

        after(:build) do |pipeline, evaluator|
          pipeline.builds << build(:ee_ci_build, report_type, :success, pipeline: pipeline, project: pipeline.project)
          create(:vulnerability_statistic, project: pipeline.project, pipeline: pipeline)
        end
      end
    end

    trait :with_container_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :container_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_container_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_container_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_cluster_image_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :cluster_image_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_cluster_image_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_cluster_image_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_dependency_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :dependency_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_dependency_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_dependency_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_sast_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :sast_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_secret_detection_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :secret_detection_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_dast_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :dast_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_license_scanning_feature_branch do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :license_scanning_feature_branch, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_license_scanning_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_license_scanning_report, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_metrics_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_metrics_alternate_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :metrics_alternate, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_cyclonedx_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :cyclonedx, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_cyclonedx_pypi_only do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :cyclonedx_pypi_only, pipeline: pipeline, project: pipeline.project)
      end
    end

    trait :with_corrupted_cyclonedx_report do
      status { :success }

      after(:build) do |pipeline, evaluator|
        pipeline.builds << build(:ee_ci_build, :corrupted_cyclonedx, pipeline: pipeline, project: pipeline.project)
      end
    end
  end
end
