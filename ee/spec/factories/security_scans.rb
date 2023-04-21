# frozen_string_literal: true

FactoryBot.define do
  factory :security_scan, class: 'Security::Scan' do
    scan_type { 'dast' }
    build factory: [:ci_build, :success]
    pipeline { build.pipeline }
    project { build.project }

    trait :with_error do
      info { { errors: [{ type: 'ParsingError', message: 'Unknown error happened' }] } }
    end

    trait :with_warning do
      info { { warnings: [{ type: 'Deprecation Warning', message: 'Schema is deprecated' }] } }
    end

    trait :latest_successful do
      latest { true }
      status { :succeeded }
    end

    trait :purged do
      status { :purged }
    end

    trait :with_findings do
      # rubocop:disable RSpec/FactoryBot/StrategyInCallback
      after(:create) do |scan|
        artifact = create(:ee_ci_job_artifact, scan.scan_type, job: scan.build, project: scan.project)
        report = create(:ci_reports_security_report, pipeline: scan.pipeline, type: scan.scan_type)

        Gitlab::Ci::Parsers.fabricate!(scan.scan_type, artifact.file.read, report).parse!
        report = Security::MergeReportsService.new(report).execute

        report.findings.each do |finding|
          create(
            :security_finding,
            severity: finding.severity,
            confidence: finding.confidence,
            uuid: finding.uuid,
            deduplicated: true,
            scan: scan
          )
        end
      end
      # rubocop:enable RSpec/FactoryBot/StrategyInCallback
    end
  end
end
