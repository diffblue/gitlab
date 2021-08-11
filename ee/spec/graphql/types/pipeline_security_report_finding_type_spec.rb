# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineSecurityReportFinding'] do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, :with_sast_report, project: project) }

  let(:fields) do
    %i[report_type
       name
       severity
       confidence
       scanner
       identifiers
       project_fingerprint
       uuid
       project
       description
       location
       falsePositive
       solution
       state]
  end

  before do
    stub_licensed_features(sast: true, security_dashboard: true, sast_fp_reduction: true)

    project.add_developer(user)
  end

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  specify { expect(described_class.graphql_name).to eq('PipelineSecurityReportFinding') }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'false_positive' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              securityReportFindings {
                nodes {
                  falsePositive
                }
              }
            }
          }
        }
      )
    end

    context 'when the vulnerability has a false-positive flag' do
      before do
        security_finding = pipeline.security_reports.reports['sast'].findings.first
        vulnerability_finding = create(:vulnerabilities_finding, uuid: security_finding.uuid, pipelines: [pipeline], project: pipeline.project)
        create(:vulnerabilities_flag, finding: vulnerability_finding)
      end

      it 'returns false-positive value' do
        vulnerabilities = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(vulnerabilities.first['falsePositive']).to be(true)
        expect(vulnerabilities.last['falsePositive']).to be(false)
      end
    end

    context 'when the vulnerability does not have any false-positive flag' do
      it 'returns false for false-positive field' do
        vulnerabilities = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(vulnerabilities.first['falsePositive']).to be(false)
      end
    end

    context 'when there exists no license' do
      before do
        stub_licensed_features(sast: true, security_dashboard: true, sast_fp_reduction: false)
      end

      it 'returns nil for false-positive field' do
        vulnerabilities = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(vulnerabilities.first['falsePositive']).to be_nil
      end
    end

    context 'when vulnerability_flags FF has been disabled' do
      before do
        stub_feature_flags(vulnerability_flags: false)
      end

      it 'exposes an error message' do
        error_msg = subject.dig('errors').first['message']
        expect(error_msg).to eql("Field 'falsePositive' doesn't exist on type 'PipelineSecurityReportFinding'")
      end
    end
  end
end
