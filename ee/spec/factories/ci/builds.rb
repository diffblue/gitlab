# frozen_string_literal: true
FactoryBot.define do
  factory :ee_ci_build, class: 'Ci::Build', parent: :ci_build do
    trait :protected_environment_failure do
      failed
      failure_reason { Ci::Build.failure_reasons[:protected_environment_failure] }
    end

    %i[api_fuzzing codequality container_scanning cluster_image_scanning dast dependency_scanning license_scanning performance browser_performance load_performance sast secret_detection coverage_fuzzing].each do |report_type|
      trait "legacy_#{report_type}".to_sym do
        success
        artifacts
        name { report_type }

        options do
          {
            artifacts: {
              paths: [Ci::JobArtifact::DEFAULT_FILE_NAMES[report_type]]
            }
          }
        end
      end

      trait report_type do
        options do
          {
            artifacts: {
              reports: {
                report_type => Ci::JobArtifact::DEFAULT_FILE_NAMES[report_type]
              }
            }
          }
        end

        after(:build) do |build|
          build.job_artifacts << build(:ee_ci_job_artifact, report_type, job: build)
        end

        after(:create) do |build|
          if Security::Scan.scan_types.include?(report_type)
            build.security_scans << build(:security_scan, scan_type: report_type, build: build)
          end
        end
      end
    end

    trait :dependency_list do
      name { :dependency_scanning }

      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :dependency_list, job: build)
      end
    end

    trait :metrics do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :metrics, job: build)
      end
    end

    trait :metrics_alternate do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :metrics_alternate, job: build)
      end
    end

    trait :sast_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :sast_feature_branch, job: build)
      end
    end

    trait :secret_detection_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :secret_detection_feature_branch, job: build)
      end
    end

    trait :dast_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :dast_feature_branch, job: build)
      end
    end

    trait :container_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :container_scanning_feature_branch, job: build)
      end
    end

    trait :corrupted_container_scanning_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :corrupted_container_scanning_report, job: build)
      end
    end

    trait :cluster_image_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :cluster_image_scanning_feature_branch, job: build)
      end
    end

    trait :corrupted_cluster_image_scanning_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :corrupted_cluster_image_scanning_report, job: build)
      end
    end

    trait :dependency_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :dependency_scanning_feature_branch, job: build)
      end
    end

    trait :dependency_scanning_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :dependency_scanning_report, job: build)
      end
    end

    trait :corrupted_dependency_scanning_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :corrupted_dependency_scanning_report, job: build)
      end
    end

    trait :license_scanning_feature_branch do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :license_scanning_feature_branch, job: build)
      end
    end

    trait :corrupted_license_scanning_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :license_scan, :with_corrupted_data, job: build)
      end
    end

    trait :low_severity_dast_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :low_severity_dast_report, job: build)
      end
    end

    %w[1 1_1 2 2_1].each do |version|
      trait :"license_scan_v#{version}" do
        after :build do |build|
          build.job_artifacts << build(:ee_ci_job_artifact, :license_scan, :"v#{version}", job: build)
        end
      end
    end

    trait :license_scanning_custom_license do
      after :build do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :license_scanning_custom_license, job: build)
      end
    end

    trait :requirements_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :all_passing_requirements, job: build)
      end
    end

    trait :requirements_v2_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :all_passing_requirements_v2, job: build)
      end
    end

    trait :coverage_fuzzing_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :coverage_fuzzing, job: build)
      end
    end

    trait :api_fuzzing_report do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :api_fuzzing, job: build)
      end
    end

    trait :cyclonedx do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :cyclonedx, job: build)
      end
    end

    trait :cyclonedx_pypi_only do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :cyclonedx_pypi_only, job: build)
      end
    end

    trait :corrupted_cyclonedx do
      after(:build) do |build|
        build.job_artifacts << build(:ee_ci_job_artifact, :corrupted_cyclonedx, job: build)
      end
    end
  end
end
