# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Pipeline'] do
  it { expect(described_class.graphql_name).to eq('Pipeline') }

  it 'includes the ee specific fields' do
    expected_fields = %w[
      security_report_summary
      security_report_findings
      code_quality_reports
      dast_profile
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'security_report_finding' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let_it_be(:build) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
    let_it_be(:artifact) { create(:ee_ci_job_artifact, :sast, job: build) }
    let_it_be(:report) { create(:ci_reports_security_report, type: :sast) }
    let_it_be(:user) { create(:user) }
    let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :sast, build: build) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              securityReportFinding(uuid: "#{uuid}") {
                title
                reportType
              }
            }
          }
        }
      )
    end

    before do
      stub_licensed_features(sast: true, security_dashboard: true)

      project.add_developer(user)
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when no security findings exist for the pipeline' do
      let(:uuid) { "any-uuid" }

      it 'returns null' do
        security_finding = subject.dig('data', 'project', 'pipeline', 'securityReportFinding')

        expect(pipeline.security_findings.count).to be_zero
        expect(security_finding).to be_nil
      end
    end

    context 'when security findings exist for the pipeline' do
      before :all do
        content = File.read(artifact.file.path)
        Gitlab::Ci::Parsers::Security::Sast.parse!(content, report)
        report.merge!(report)

        scan.report_findings.each do |finding|
          create(:security_finding,
                 severity: finding.severity,
                 confidence: finding.confidence,
                 project_fingerprint: finding.project_fingerprint,
                 deduplicated: true,
                 scan: scan,
                 uuid: finding.uuid)
        end
      end

      context 'when the specified security finding is not found for the pipeline' do
        let(:uuid) { "bad-uuid" }

        it 'returns null' do
          security_finding = subject.dig('data', 'project', 'pipeline', 'securityReportFinding')

          expect(pipeline.security_findings).not_to be_empty
          expect(security_finding).to be_nil
        end
      end

      context 'when the security finding is found' do
        let(:uuid) { expected_security_finding.uuid }
        let(:expected_security_finding) { Security::Finding.first }
        let(:expected_report_finding) do
          expected_security_finding.scan.report_findings.find { |f| f.uuid == expected_security_finding.uuid }
        end

        it 'returns the security finding' do
          security_finding = subject.dig('data', 'project', 'pipeline', 'securityReportFinding')

          expect(security_finding["title"]).to eq(expected_report_finding.name)
          expect(security_finding["reportType"]).to eq(expected_report_finding.report_type.upcase)
        end
      end
    end
  end
end
