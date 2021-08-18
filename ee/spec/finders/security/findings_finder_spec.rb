# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::FindingsFinder do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build_1) { create(:ci_build, :success, name: 'dependency_scanning', pipeline: pipeline) }
  let_it_be(:build_2) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:artifact_ds) { create(:ee_ci_job_artifact, :dependency_scanning, job: build_1) }
  let_it_be(:artifact_sast) { create(:ee_ci_job_artifact, :sast, job: build_2) }
  let_it_be(:report_ds) { create(:ci_reports_security_report, pipeline: pipeline, type: :dependency_scanning) }
  let_it_be(:report_sast) { create(:ci_reports_security_report, pipeline: pipeline, type: :sast) }

  let(:severity_levels) { nil }
  let(:confidence_levels) { nil }
  let(:report_types) { nil }
  let(:scope) { nil }
  let(:page) { nil }
  let(:per_page) { nil }
  let(:service_object) { described_class.new(pipeline, params: params) }
  let(:params) do
    {
      severity: severity_levels,
      confidence: confidence_levels,
      report_type: report_types,
      scope: scope,
      page: page,
      per_page: per_page
    }
  end

  describe '#execute' do
    context 'when the pipeline does not have security findings' do
      subject { service_object.execute }

      it { is_expected.to be_nil }
    end

    context 'when the pipeline has security findings' do
      let(:finder_result) { service_object.execute }

      before(:all) do
        ds_content = File.read(artifact_ds.file.path)
        Gitlab::Ci::Parsers::Security::DependencyScanning.parse!(ds_content, report_ds)
        report_ds.merge!(report_ds)
        sast_content = File.read(artifact_sast.file.path)
        Gitlab::Ci::Parsers::Security::Sast.parse!(sast_content, report_sast)
        report_sast.merge!(report_sast)

        { artifact_ds => report_ds, artifact_sast => report_sast }.each do |artifact, report|
          scan = create(:security_scan, scan_type: artifact.job.name, build: artifact.job)

          report.findings.each_with_index do |finding, index|
            create(:security_finding,
                   severity: finding.severity,
                   confidence: finding.confidence,
                   project_fingerprint: finding.project_fingerprint,
                   uuid: finding.uuid,
                   deduplicated: true,
                   position: index,
                   scan: scan)

            create(:vulnerabilities_finding, uuid: finding.uuid, project: pipeline.project)
          end
        end

        Security::Finding.by_project_fingerprints('204732fd9e78053dee33a0cad08930c129da197d')
                         .update_all(deduplicated: false)

        create(:vulnerability_feedback,
               :dismissal,
               project: pipeline.project,
               category: :sast,
               project_fingerprint: 'db759283b7fb13eae48a3f60db4c7506cdab8f26')
      end

      before do
        stub_licensed_features(sast: true, dependency_scanning: true)
      end

      context 'N+1 queries' do
        it 'does not cause N+1 queries' do
          expect { finder_result }.not_to exceed_query_limit(11)
        end
      end

      describe '#current_page' do
        subject { finder_result.current_page }

        context 'when the page is not provided' do
          it { is_expected.to be(1) }
        end

        context 'when the page is provided' do
          let(:page) { 2 }

          it { is_expected.to be(2) }
        end
      end

      describe '#limit_value' do
        subject { finder_result.limit_value }

        context 'when the per_page is not provided' do
          it { is_expected.to be(20) }
        end

        context 'when the per_page is provided' do
          let(:per_page) { 100 }

          it { is_expected.to be(100) }
        end
      end

      describe '#total_pages' do
        subject { finder_result.total_pages }

        context 'when the per_page is not provided' do
          it { is_expected.to be(1) }
        end

        context 'when the per_page is provided' do
          let(:per_page) { 3 }

          it { is_expected.to be(3) }
        end
      end

      describe '#total_count' do
        subject { finder_result.total_count }

        context 'when the scope is not provided' do
          it { is_expected.to be(8) }
        end

        context 'when the scope is provided as `all`' do
          let(:scope) { 'all' }

          it { is_expected.to be(8) }
        end
      end

      describe '#next_page' do
        subject { finder_result.next_page }

        context 'when the page is not provided' do
          # Limit per_page to force pagination on smaller dataset
          let(:per_page) { 2 }

          it { is_expected.to be(2) }
        end

        context 'when the page is provided' do
          let(:page) { 2 }

          it { is_expected.to be_nil }
        end
      end

      describe '#prev_page' do
        subject { finder_result.prev_page }

        context 'when the page is not provided' do
          it { is_expected.to be_nil }
        end

        context 'when the page is provided' do
          let(:page) { 2 }
          # Limit per_page to force pagination on smaller dataset
          let(:per_page) { 2 }

          it { is_expected.to be(1) }
        end
      end

      describe '#vulnerability_flags' do
        before do
          stub_licensed_features(sast_fp_reduction: true)
        end

        context 'with no vulnerability flags present' do
          it 'does not have any vulnerability flag' do
            expect(finder_result.findings).to all(have_attributes(vulnerability_flags: be_empty))
          end
        end

        context 'with some vulnerability flags present' do
          before do
            create(:vulnerabilities_flag, finding: pipeline.project.vulnerability_findings.first)
            create(:vulnerabilities_flag, finding: pipeline.project.vulnerability_findings.last)
          end

          it 'has some vulnerability_findings with vulnerability flag' do
            expect(finder_result.findings).to include(have_attributes(vulnerability_flags: be_present))
          end

          it 'does not have any vulnerability_flag if license is not available' do
            stub_licensed_features(sast_fp_reduction: false)

            expect(finder_result.findings).to all(have_attributes(vulnerability_flags: be_empty))
          end
        end
      end

      describe '#findings' do
        subject { finder_result.findings.map(&:project_fingerprint) }

        context 'with the default parameters' do
          let(:expected_fingerprints) do
            %w[
              4ae096451135db224b9e16818baaca8096896522
              0bfcfbb70b15a7cecef9a1ea39df15ecfd88949f
              157f362acf654c60e224400f59a088e1c01b369f
              b9c0d1cdc7cb9c180ebb6981abbddc2df0172509
              baf3e36cda35331daed7a3e80155533d552844fa
              3204893d5894c74aaee86ce5bc28427f9f14e512
              98366a28fa80b23a1dafe2b36e239a04909495c4
              9a644ee1b89ac29d6175dc1170914f47b0531635
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the page is provided' do
          let(:page) { 2 }
          # Limit per_page to force pagination on smaller dataset
          let(:per_page) { 2 }
          let(:expected_fingerprints) do
            %w[
              0bfcfbb70b15a7cecef9a1ea39df15ecfd88949f
              baf3e36cda35331daed7a3e80155533d552844fa
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the per_page is provided' do
          let(:per_page) { 1 }
          let(:expected_fingerprints) do
            %w[
              4ae096451135db224b9e16818baaca8096896522
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the `severity_levels` is provided' do
          let(:severity_levels) { [:medium] }
          let(:expected_fingerprints) do
            %w[
              0bfcfbb70b15a7cecef9a1ea39df15ecfd88949f
              9a644ee1b89ac29d6175dc1170914f47b0531635
              b9c0d1cdc7cb9c180ebb6981abbddc2df0172509
              baf3e36cda35331daed7a3e80155533d552844fa
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the `confidence_levels` is provided' do
          let(:confidence_levels) { [:low] }
          let(:expected_fingerprints) do
            %w[
              98366a28fa80b23a1dafe2b36e239a04909495c4
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the `report_types` is provided' do
          let(:report_types) { :dependency_scanning }
          let(:expected_fingerprints) do
            %w[
              3204893d5894c74aaee86ce5bc28427f9f14e512
              157f362acf654c60e224400f59a088e1c01b369f
              4ae096451135db224b9e16818baaca8096896522
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when the `scope` is provided as `all`' do
          let(:scope) { 'all' }

          let(:expected_fingerprints) do
            %w[
              4ae096451135db224b9e16818baaca8096896522
              157f362acf654c60e224400f59a088e1c01b369f
              baf3e36cda35331daed7a3e80155533d552844fa
              0bfcfbb70b15a7cecef9a1ea39df15ecfd88949f
              98366a28fa80b23a1dafe2b36e239a04909495c4
              b9c0d1cdc7cb9c180ebb6981abbddc2df0172509
              3204893d5894c74aaee86ce5bc28427f9f14e512
              9a644ee1b89ac29d6175dc1170914f47b0531635
            ]
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when there is a retried build' do
          let(:retried_build) { create(:ci_build, :success, :retried, name: 'dependency_scanning', pipeline: pipeline) }
          let(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning, job: retried_build) }
          let(:report) { create(:ci_reports_security_report, pipeline: pipeline, type: :dependency_scanning) }
          let(:report_types) { :dependency_scanning }
          let(:expected_fingerprints) do
            %w[
              3204893d5894c74aaee86ce5bc28427f9f14e512
              157f362acf654c60e224400f59a088e1c01b369f
              4ae096451135db224b9e16818baaca8096896522
            ]
          end

          before do
            retried_content = File.read(artifact.file.path)
            Gitlab::Ci::Parsers::Security::DependencyScanning.parse!(retried_content, report)
            report.merge!(report)

            scan = create(:security_scan, scan_type: retried_build.name, build: retried_build)

            report.findings.each_with_index do |finding, index|
              create(:security_finding,
                     severity: finding.severity,
                     confidence: finding.confidence,
                     project_fingerprint: finding.project_fingerprint,
                     uuid: finding.uuid,
                     deduplicated: true,
                     position: index,
                     scan: scan)
            end
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end

        context 'when a build has more than one security report artifacts' do
          let(:report_types) { :secret_detection }
          let(:secret_detection_report) { create(:ci_reports_security_report, pipeline: pipeline, type: :secret_detection) }
          let(:expected_fingerprints) { secret_detection_report.findings.map(&:project_fingerprint) }

          before do
            scan = create(:security_scan, scan_type: :secret_detection, build: build_2)
            artifact = create(:ee_ci_job_artifact, :secret_detection, job: build_2)
            report_content = File.read(artifact.file.path)

            Gitlab::Ci::Parsers::Security::SecretDetection.parse!(report_content, secret_detection_report)

            secret_detection_report.findings.each_with_index do |finding, index|
              create(:security_finding,
                     severity: finding.severity,
                     confidence: finding.confidence,
                     project_fingerprint: finding.project_fingerprint,
                     uuid: finding.uuid,
                     deduplicated: true,
                     position: index,
                     scan: scan)
            end
          end

          it { is_expected.to match_array(expected_fingerprints) }
        end
      end
    end
  end
end
