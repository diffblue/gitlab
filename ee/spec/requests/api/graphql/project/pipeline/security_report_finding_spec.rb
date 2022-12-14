# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).securityReportFinding',
feature_category: :continuous_integration do
  include GraphqlHelpers

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
            securityReportFinding(uuid: "#{security_finding.uuid}") {
              confidence
              severity
              reportType
              name
              scanner {
                name
              }
              projectFingerprint
              identifiers {
                name
              }
              uuid
              solution
              description
              project {
                fullPath
                visibility
              }
            }
          }
        }
      }
    )
  end

  let(:security_finding) { Security::Finding.first }
  let(:security_report_finding) { subject.dig('project', 'pipeline', 'securityReportFinding') }

  before_all do
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

  subject do
    post_graphql(query, current_user: user)
    graphql_data
  end

  context 'when the required features are enabled' do
    before do
      stub_licensed_features(sast: true, security_dashboard: true)
    end

    context 'when user is member of the project' do
      let(:expected_finding) do
        security_finding.scan.report_findings.find { |f| f.uuid == security_finding.uuid }
      end

      before do
        project.add_developer(user)
      end

      it 'returns all the queried fields', :aggregate_failures do
        expect(security_report_finding.dig('project', 'fullPath')).to eq(project.full_path)
        expect(security_report_finding.dig('project', 'visibility')).to eq(project.visibility)
        expect(security_report_finding['identifiers'].length).to eq(expected_finding.identifiers.length)
        expect(security_report_finding['confidence']).to eq(expected_finding.confidence)
        expect(security_report_finding['severity']).to eq(expected_finding.severity.upcase)
        expect(security_report_finding['reportType']).to eq(expected_finding.report_type.upcase)
        expect(security_report_finding['name']).to eq(expected_finding.name)
        expect(security_report_finding['uuid']).to eq(expected_finding.uuid)
        expect(security_report_finding['solution']).to eq(expected_finding.solution)
        expect(security_report_finding['description']).to eq(expected_finding.description)
      end
    end

    context 'when user is not a member of the project' do
      it 'returns no vulnerability findings' do
        expect(security_report_finding).to be_nil
      end
    end
  end

  context 'when the required features are disabled' do
    before do
      stub_licensed_features(sast: false, security_dashboard: false)
    end

    it 'returns no vulnerability findings' do
      expect(security_report_finding).to be_nil
    end
  end
end
