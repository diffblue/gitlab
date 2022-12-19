# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineSecurityReportFinding'], feature_category: :threat_insights do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, :with_sast_report, project: project) }

  let(:fields) do
    %i[report_type
       name
       title
       severity
       confidence
       scanner
       identifiers
       links
       assets
       evidence
       project_fingerprint
       uuid
       project
       description
       location
       falsePositive
       solution
       state
       details
       description_html
       vulnerability]
  end

  before do
    stub_licensed_features(sast: true, security_dashboard: true, sast_fp_reduction: true)

    project.add_developer(user)
  end

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  specify { expect(described_class.graphql_name).to eq('PipelineSecurityReportFinding') }
  specify { expect(described_class).to require_graphql_authorizations(:read_security_resource) }

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

    context 'when the security finding has a false-positive flag' do
      before do
        allow_next_instance_of(Gitlab::Ci::Reports::Security::Finding) do |finding|
          allow(finding).to receive(:flags).and_return([create(:ci_reports_security_flag)]) if finding.report_type == 'sast'
        end
      end

      it 'returns false-positive value' do
        security_findings = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(security_findings.first['falsePositive']).to be(true)
      end
    end

    context 'when the security finding does not have any false-positive flag' do
      it 'returns false for false-positive field' do
        security_findings = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(security_findings.first['falsePositive']).to be(false)
      end
    end

    context 'when there exists no license' do
      before do
        stub_licensed_features(sast: true, security_dashboard: true, sast_fp_reduction: false)
      end

      it 'returns nil for false-positive field' do
        security_findings = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(security_findings.first['falsePositive']).to be_nil
      end
    end
  end

  describe 'vulnerability' do
    let_it_be(:build) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
    let_it_be(:artifact) { create(:ee_ci_job_artifact, :sast, job: build) }
    let_it_be(:report) { create(:ci_reports_security_report, type: :sast, pipeline: pipeline) }
    let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :sast, build: artifact.job) }
    let_it_be(:security_findings) { create_security_findings }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pipeline(iid: "#{pipeline.iid}") {
              securityReportFindings {
                nodes {
                  uuid
                  vulnerability {
                    description
                    issueLinks {
                      nodes {
                        issue {
                          description
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'returns no vulnerabilities for the security findings when none exists' do
      result_findings = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

      expect(result_findings.first['vulnerabilty']).to be_nil
    end

    context 'when the security finding has a related vulnerability' do
      let_it_be(:vulnerability) { create(:vulnerability, :with_issue_links, project: project) }
      let_it_be(:vulnerability_finding) { create(:vulnerabilities_finding, project: project, vulnerability: vulnerability, uuid: security_findings.first.uuid) }

      it 'returns vulnerabilities for the security findings' do
        result_findings = subject.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')

        expect(result_findings.first['vulnerability']['description']).to eq(vulnerability.description)
      end

      it 'avoids N+1 queries' do
        # Warm up table schema and other data (e.g. SAML providers, license)
        GitlabSchema.execute(query, context: { current_user: user })

        control_count = ActiveRecord::QueryRecorder.new { run_with_clean_state(query, context: { current_user: user }) }.count

        response = GitlabSchema.execute(query, context: { current_user: user })
        vulnerabilities = response.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes').pluck('vulnerability').compact
        issues = vulnerabilities.pluck('issueLinks').flatten.pluck('nodes').flatten
        expect(vulnerabilities.count).to eq(1)
        expect(issues.count).to eq(2)

        new_vulnerability = create(:vulnerability, :with_issue_links, project: project)
        create(:vulnerabilities_finding, project: project, vulnerability: new_vulnerability, uuid: security_findings.second.uuid)

        expect { run_with_clean_state(query, context: { current_user: user }) }.not_to exceed_query_limit(control_count)

        response = GitlabSchema.execute(query, context: { current_user: user })
        vulnerabilities = response.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes').pluck('vulnerability').compact
        issues = vulnerabilities.pluck('issueLinks').flatten.pluck('nodes').flatten
        expect(vulnerabilities.count).to eq(2)
        expect(issues.count).to eq(4)
      end
    end
  end

  def create_security_findings
    content = File.read(artifact.file.path)
    Gitlab::Ci::Parsers::Security::Sast.parse!(content, report)
    report.merge!(report)
    report.findings.map do |finding|
      create(:security_finding,
             severity: finding.severity,
             confidence: finding.confidence,
             uuid: finding.uuid,
             scan: scan)
    end
  end
end
