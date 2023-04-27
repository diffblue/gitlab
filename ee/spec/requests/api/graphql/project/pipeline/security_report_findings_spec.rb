# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).securityReportFindings',
feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            securityReportFindings(reportType: ["sast", "dast"]) {
              nodes {
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
      }
    )
  end

  let(:security_report_findings) { subject.dig('project', 'pipeline', 'securityReportFindings', 'nodes') }

  before_all do
    create(:ci_build, :success, name: 'dast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :dast_large_scanned_resources_field, job: job, project: project)
    end
    create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) do |job|
      create(:ee_ci_job_artifact, :sast, job: job, project: project)
    end
  end

  subject do
    post_graphql(query, current_user: user)
    graphql_data
  end

  context 'when the required features are enabled' do
    before do
      stub_licensed_features(sast: true, dast: true, security_dashboard: true)
    end

    context 'when user is member of the project' do
      before do
        project.add_developer(user)
      end

      it 'returns all the vulnerability findings' do
        expect(security_report_findings.length).to eq(25)
      end

      it 'returns all the queried fields', :aggregate_failures do
        security_report_finding = security_report_findings.first

        expect(security_report_finding.dig('project', 'fullPath')).to eq(project.full_path)
        expect(security_report_finding.dig('project', 'visibility')).to eq(project.visibility)
        expect(security_report_finding['identifiers'].length).to eq(3)
        expect(security_report_finding['severity']).not_to be_nil
        expect(security_report_finding['reportType']).not_to be_nil
        expect(security_report_finding['name']).not_to be_nil
        expect(security_report_finding['projectFingerprint']).not_to be_nil
        expect(security_report_finding['uuid']).not_to be_nil
        expect(security_report_finding['solution']).not_to be_nil
        expect(security_report_finding['description']).not_to be_nil
      end
    end

    context 'when user is not a member of the project' do
      it 'returns no vulnerability findings' do
        expect(security_report_findings).to be_blank
      end
    end
  end

  context 'when the required features are disabled' do
    before do
      stub_licensed_features(sast: false, dast: false, security_dashboard: false)
    end

    it 'returns no vulnerability findings' do
      expect(security_report_findings).to be_blank
    end
  end
end
