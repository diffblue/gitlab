# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).securityReportSummary', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }

  let_it_be(:build_sast) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:artifact_sast) { create(:ee_ci_job_artifact, :sast, job: build_sast) }
  let_it_be(:report_sast) { create(:ci_reports_security_report, type: :sast) }

  let_it_be(:build_dast) { create(:ci_build, :success, name: 'dast', pipeline: pipeline) }
  let_it_be(:artifact_dast) { create(:ee_ci_job_artifact, :dast_large_scanned_resources_field, job: build_dast) }
  let_it_be(:report_dast) { create(:ci_reports_security_report, type: :dast) }

  let_it_be(:user) { create(:user) }

  before_all do
    sast_content = File.read(artifact_sast.file.path)
    Gitlab::Ci::Parsers::Security::Sast.parse!(sast_content, report_sast)
    report_sast.merge!(report_sast)

    dast_content = File.read(artifact_dast.file.path)
    Gitlab::Ci::Parsers::Security::Dast.parse!(dast_content, report_dast)
    report_dast.merge!(report_dast)

    { artifact_dast => report_dast, artifact_sast => report_sast }.each do |artifact, report|
      scan = create(:security_scan, scan_type: artifact.job.name, build: artifact.job)

      report.findings.each_with_index do |finding, index|
        create(:security_finding,
              severity: finding.severity,
              confidence: finding.confidence,
              project_fingerprint: finding.project_fingerprint,
              deduplicated: true,
              scan: scan)
      end
    end
  end

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            securityReportSummary {
              dast {
                scannedResourcesCount
                vulnerabilitiesCount
                scannedResources {
                  nodes {
                    url
                    requestMethod
                  }
                }
              }
              sast {
                vulnerabilitiesCount
              }
            }
          }
        }
      }
    )
  end

  let(:security_report_summary) { subject.dig('project', 'pipeline', 'securityReportSummary') }

  subject do
    post_graphql(query, current_user: user)
    graphql_data
  end

  context 'when the required features are enabled' do
    before do
      stub_licensed_features(sast: true, dependency_scanning: true, container_scanning: true, dast: true, security_dashboard: true)
    end

    context 'when user is member of the project' do
      before do
        project.add_developer(user)
      end

      it 'shows the vulnerabilitiesCount and scannedResourcesCount' do
        expect(security_report_summary.dig('dast', 'vulnerabilitiesCount')).to eq(20)
        expect(security_report_summary.dig('dast', 'scannedResourcesCount')).to eq(26)
        expect(security_report_summary.dig('sast', 'vulnerabilitiesCount')).to eq(5)
      end

      it 'shows the first 20 scanned resources' do
        dast_scanned_resources = security_report_summary.dig('dast', 'scannedResources', 'nodes')

        expect(dast_scanned_resources.length).to eq(20)
      end

      it 'returns nil for the scannedResourcesCsvPath' do
        expect(security_report_summary.dig('dast', 'scannedResourcesCsvPath')).to be_nil
      end
    end

    context 'when user is not a member of the project' do
      it 'returns no scanned resources' do
        expect(security_report_summary).to be_nil
      end
    end
  end

  context 'when the required features are disabled' do
    before do
      stub_licensed_features(sast: false, dependency_scanning: false, container_scanning: false, dast: false, security_dashboard: false)
    end

    it 'returns no scanned resources' do
      expect(security_report_summary).to be_nil
    end
  end
end
