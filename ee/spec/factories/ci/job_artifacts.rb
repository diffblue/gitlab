# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: '::Ci::JobArtifact', parent: :ci_job_artifact do
    trait :verification_succeeded do
      common_security_report # with file
      verification_checksum { 'abc' }
      verification_state { Ci::JobArtifact.verification_state_value(:verification_succeeded) }
    end

    trait :verification_failed do
      common_security_report # with file
      verification_failure { 'Could not calculate the checksum' }
      verification_state { Ci::JobArtifact.verification_state_value(:verification_failed) }
    end

    trait :sast_without_any_identifiers do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-sast-report-without-any-identifiers.json'), 'application/json')
      end
    end

    trait :sast_with_signatures_and_vulnerability_flags do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-sast-report-with-signatures-and-flags.json'), 'application/json')
      end
    end

    trait :sast_with_signatures_and_vulnerability_flags_with_duplicate_identifiers do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-sast-report-with-signatures-and-flags-duplicate-identifiers.json'), 'application/json')
      end
    end

    trait :semgrep_web_vulnerabilities do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/semgrep-web-vulnerabilities.json'),
          'application/json'
        )
      end
    end

    trait :semgrep_api_vulnerabilities do
      file_type { :sast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/semgrep-api-vulnerabilities.json'),
          'application/json'
        )
      end
    end

    trait :dast_with_evidence do
      file_type { :dast }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-with-evidence.json'), 'application/json')
      end
    end

    trait :dast do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report.json'), 'application/json')
      end
    end

    trait :dast_missing_version do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-missing-version.json'), 'application/json')
      end
    end

    trait :dast_14_0_2 do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-14.0.2.json'), 'application/json')
      end
    end

    trait :dast_feature_branch do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-dast-report.json'), 'application/json')
      end
    end

    trait :dast_multiple_sites do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-multiple-sites.json'), 'application/json')
      end
    end

    trait :dast_missing_scan_field do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-missing-scan.json'), 'application/json')
      end
    end

    trait :dast_large_scanned_resources_field do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-large-scanned-resources.json'), 'application/json')
      end
    end

    trait :low_severity_dast_report do
      file_format { :raw }
      file_type { :dast }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report-low-severity.json'), 'application/json')
      end
    end

    trait :license_scanning do
      file_type { :license_scanning }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-license-scanning-report.json'), 'application/json')
      end
    end

    trait :license_scanning_feature_branch do
      file_type { :license_scanning }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-license-scanning-report.json'), 'application/json')
      end
    end

    trait :license_scanning_custom_license do
      file_type { :license_scanning }
      file_format { :raw }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/license_compliance/gl-license-scanning-report-custom-license.json'), 'application/json')
      end
    end

    trait :performance do
      file_format { :raw }
      file_type { :performance }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :browser_performance do
      file_format { :raw }
      file_type { :browser_performance }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :load_performance do
      file_format { :raw }
      file_type { :load_performance }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'text/plain')
      end
    end

    trait :dependency_scanning do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :dependency_scanning_multiple_scanners do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dependency-scanning-report-with-multiple-scanners.json'),
          'application/json'
        )
      end
    end

    trait :dependency_scanning_remediation do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/remediations/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :dependency_scanning_feature_branch do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :corrupted_dependency_scanning_report do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :container_scanning do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-container-scanning-report.json'), 'application/json')
      end
    end

    trait :cluster_image_scanning do
      file_format { :raw }
      file_type { :cluster_image_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-cluster-image-scanning-report.json'), 'application/json')
      end
    end

    trait :container_scanning_feature_branch do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-container-scanning-report.json'), 'application/json')
      end
    end

    trait :corrupted_container_scanning_report do
      file_format { :raw }
      file_type { :container_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :cluster_image_scanning_feature_branch do
      file_format { :raw }
      file_type { :cluster_image_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/feature-branch/gl-cluster-image-scanning-report.json'), 'application/json')
      end
    end

    trait :corrupted_cluster_image_scanning_report do
      file_format { :raw }
      file_type { :cluster_image_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/trace/sample_trace'), 'application/json')
      end
    end

    trait :metrics do
      file_format { :gzip }
      file_type { :metrics }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/metrics.txt.gz'), 'application/x-gzip')
      end
    end

    trait :metrics_alternate do
      file_format { :gzip }
      file_type { :metrics }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/alternate_metrics.txt.gz'), 'application/x-gzip')
      end
    end

    trait :dependency_list do
      file_format { :raw }
      file_type { :dependency_scanning }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/dependency_list/gl-dependency-scanning-report.json'), 'application/json')
      end
    end

    trait :license_scan do
      file_type { :license_scanning }
      file_format { :raw }
    end

    %w[1 1_1 2 2_1].each do |version|
      trait :"v#{version}" do
        after(:build) do |artifact, _|
          filename = "gl-#{artifact.file_type.dasherize}-report-v#{version.sub(/_/, '.')}.json"
          path = Rails.root.join("ee/spec/fixtures/security_reports/license_compliance/#{filename}")
          artifact.file = fixture_file_upload(path, "application/json")
        end
      end
    end

    trait :with_corrupted_data do
      after :build do |artifact, _|
        path = Rails.root.join('spec/fixtures/trace/sample_trace')
        artifact.file = fixture_file_upload(path, 'application/json')
      end
    end

    trait :all_passing_requirements do
      file_format { :raw }
      file_type { :requirements }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/requirements_management/all_passing_report.json'), 'application/json')
      end
    end

    trait :all_passing_requirements_v2 do
      file_format { :raw }
      file_type { :requirements_v2 }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/requirements_management/all_passing_report.json'), 'application/json')
      end
    end

    trait :coverage_fuzzing do
      file_format { :raw }
      file_type { :coverage_fuzzing }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-coverage-fuzzing-report.json'),
          'application/json')
      end
    end

    trait :api_fuzzing do
      file_format { :raw }
      file_type { :api_fuzzing }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/security_reports/master/gl-api-fuzzing-report.json'),
          'application/json')
      end
    end

    trait :cyclonedx do
      file_format { :gzip }
      file_type { :cyclonedx }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/sbom/gl-sbom.cdx.json.gz'),
          'application/x-gzip')
      end
    end

    trait :cyclonedx_pypi_only do
      file_format { :gzip }
      file_type { :cyclonedx }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/sbom/gl-sbom-pypi-only.cdx.json.gz'),
          'application/x-gzip')
      end
    end

    trait :corrupted_cyclonedx do
      file_format { :gzip }
      file_type { :cyclonedx }

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('ee/spec/fixtures/sbom/gl-sbom-corrupted.cdx.json.gz'),
          'application/x-gzip')
      end
    end
  end
end
