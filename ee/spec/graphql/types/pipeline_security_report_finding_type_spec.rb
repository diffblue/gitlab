# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PipelineSecurityReportFinding'], feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:pipeline) { create(:ci_pipeline, :with_sast_report, project: project) }

  let_it_be(:sast_build) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:sast_artifact) { create(:ee_ci_job_artifact, :sast, job: sast_build) }
  let_it_be(:sast_report) { create(:ci_reports_security_report, type: :sast, pipeline: pipeline) }
  let_it_be(:sast_scan) { create(:security_scan, :latest_successful, scan_type: :sast, build: sast_artifact.job) }
  let_it_be(:sast_findings) { create_findings(sast_scan, sast_report, sast_artifact) }

  let_it_be(:dep_scan_build) { create(:ci_build, :success, name: 'dependency_scanning', pipeline: pipeline) }
  let_it_be(:dep_scan_artifact) { create(:ee_ci_job_artifact, :dependency_scanning_remediation, job: dep_scan_build) }
  let_it_be(:dep_scan_report) { create(:ci_reports_security_report, type: :dependency_scanning, pipeline: pipeline) }
  let_it_be(:dep_scan_scan) do
    create(:security_scan, :latest_successful, scan_type: :dependency_scanning, build: dep_scan_artifact.job)
  end

  let_it_be(:dep_scan_findings) { create_findings(dep_scan_scan, dep_scan_report, dep_scan_artifact) }

  let(:fields) do
    %i[report_type
       title
       severity
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
       vulnerability
       issueLinks
       merge_request
       remediations
       dismissed_at
       dismissed_by
       dismissal_reason
       state_comment
       description_html]
  end

  let(:sast_query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            securityReportFindings(reportType: ["sast"]) {
              nodes {
                #{query_for_test}
              }
            }
          }
        }
      }
    )
  end

  let(:dep_scan_query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            securityReportFindings(reportType: ["dependency_scanning"]) {
              nodes {
                #{query_for_test}
              }
            }
          }
        }
      }
    )
  end

  before do
    stub_licensed_features(sast: true, dependency_scanning: true, security_dashboard: true, sast_fp_reduction: true)

    stub_feature_flags(deprecate_vulnerabilities_feedback: false)

    project.add_developer(user)
  end

  subject { GitlabSchema.execute(sast_query, context: { current_user: user }).as_json }

  specify { expect(described_class.graphql_name).to eq('PipelineSecurityReportFinding') }
  specify { expect(described_class).to require_graphql_authorizations(:read_security_resource) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'false_positive' do
    let(:query_for_test) do
      %(
        falsePositive
      )
    end

    context 'when the security finding has a false-positive flag' do
      before do
        allow_next_instance_of(Gitlab::Ci::Reports::Security::Finding) do |finding|
          if finding.report_type == 'sast'
            allow(finding).to receive(:flags).and_return([create(:ci_reports_security_flag)])
          end
        end
      end

      it 'returns false-positive value' do
        expect(get_findings_from_response(subject).first['falsePositive']).to be(true)
      end
    end

    context 'when the security finding does not have any false-positive flag' do
      it 'returns false for false-positive field' do
        expect(get_findings_from_response(subject).first['falsePositive']).to be(false)
      end
    end

    context 'when there exists no license' do
      before do
        stub_licensed_features(sast: true, security_dashboard: true, sast_fp_reduction: false)
      end

      it 'returns nil for false-positive field' do
        expect(get_findings_from_response(subject).first['falsePositive']).to be_nil
      end
    end
  end

  context 'when a field has specific authorization' do
    def fetch_authorizations(field_name)
      described_class.fields[field_name].instance_variable_get(:@authorize)
    end

    it 'runs the authorization' do
      expect(fetch_authorizations('vulnerability')).to include(:read_vulnerability)
    end
  end

  describe 'vulnerability' do
    let(:query_for_test) do
      %(
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
      )
    end

    it 'returns no vulnerabilities for the security findings when none exists' do
      expect(get_findings_from_response(subject).first['vulnerabilty']).to be_nil
    end

    context 'when the security finding has a related vulnerability' do
      let_it_be(:vulnerability) { create(:vulnerability, :with_issue_links, project: project) }
      let_it_be(:vulnerability_finding) do
        create(:vulnerabilities_finding, project: project, vulnerability: vulnerability, uuid: sast_findings.first.uuid)
      end

      let(:vulnerability_description) { get_findings_from_response(subject).first['vulnerability']['description'] }

      it 'returns vulnerabilities for the security findings' do
        expect(vulnerability_description).to eq(vulnerability.description)
      end

      it 'avoids N+1 queries' do
        # Warm up table schema and other data (e.g. SAML providers, license)
        GitlabSchema.execute(sast_query, context: { current_user: user })

        control_count =
          ActiveRecord::QueryRecorder.new { run_with_clean_state(sast_query, context: { current_user: user }) }.count

        vulnerabilities = get_findings_from_response(subject).pluck('vulnerability').compact
        issues = get_issues_from_vulnerabilities(vulnerabilities)
        expect(vulnerabilities.count).to eq(1)
        expect(issues.count).to eq(2)

        new_vulnerability = create(:vulnerability, :with_issue_links, project: project)
        create(:vulnerabilities_finding,
               project: project,
               vulnerability: new_vulnerability,
               uuid: sast_findings.second.uuid)

        expect { run_with_clean_state(sast_query, context: { current_user: user }) }
          .not_to exceed_query_limit(control_count)

        response = GitlabSchema.execute(sast_query, context: { current_user: user })
        vulnerabilities = get_findings_from_response(response).pluck('vulnerability').compact
        issues = get_issues_from_vulnerabilities(vulnerabilities)
        expect(vulnerabilities.count).to eq(2)
        expect(issues.count).to eq(4)
      end
    end
  end

  describe 'issue_links' do
    let(:query_for_test) do
      %(
        uuid
        issueLinks {
          nodes {
            issue {
              description
            }
          }
        }
      )
    end

    it 'returns no issues for the security findings when no vulnerability exists' do
      expect(get_findings_from_response(subject).first['issueLinks']).to be_nil
    end

    context 'when there is a vulnerabillty with no issues' do
      let_it_be(:vulnerability) { create(:vulnerability, project: project) }
      let_it_be(:vulnerability_finding) do
        create(:vulnerabilities_finding, project: project, vulnerability: vulnerability, uuid: sast_findings.first.uuid)
      end

      let(:issue_links) { get_findings_from_response(subject).first['issueLinks']['nodes'] }

      it 'returns no issues' do
        expect(issue_links).to be_empty
      end
    end

    context 'when the security finding has a related vulnerability' do
      let_it_be(:issue) { create(:issue, description: 'Vulnerability issue description', project: project) }
      let_it_be(:vulnerability) { create(:vulnerability, project: project) }
      let_it_be(:vulnerability_finding) do
        create(:vulnerabilities_finding,
               project: project,
               vulnerability: vulnerability,
               uuid: sast_findings.first.uuid)
      end

      let_it_be(:issue_link) { create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue) }

      let(:issue_description) do
        get_findings_from_response(subject).first['issueLinks']['nodes'].first['issue']['description']
      end

      it 'returns issues for the security findings' do
        expect(issue_description).to eq(issue.description)
      end

      it 'avoids N+1 queries' do
        # Warm up table schema and other data (e.g. SAML providers, license)
        GitlabSchema.execute(sast_query, context: { current_user: user })

        control_count =
          ActiveRecord::QueryRecorder.new { run_with_clean_state(sast_query, context: { current_user: user }) }.count

        findings = get_findings_from_response(subject)
        issues = get_issues_from_findings(findings)
        expect(issues.count).to eq(1)

        new_vulnerability = create(:vulnerability, :with_issue_links, project: project)
        create(:vulnerabilities_finding,
               project: project,
               vulnerability: new_vulnerability,
               uuid: sast_findings.second.uuid)

        expect { run_with_clean_state(sast_query, context: { current_user: user }) }
          .not_to exceed_query_limit(control_count)

        response = GitlabSchema.execute(sast_query, context: { current_user: user })
        findings = get_findings_from_response(response)
        issues = get_issues_from_findings(findings)
        expect(issues.count).to eq(3)
      end
    end
  end

  describe 'merge_request' do
    let(:query_for_test) do
      %(
        uuid
        mergeRequest {
          description
        }
      )
    end

    it 'returns no merge requests for the security findings when no vulnerability finding exists' do
      expect(get_findings_from_response(subject).first['mergeRequest']).to be_nil
    end

    context 'when there is a security finding with no merge request' do
      let_it_be(:vulnerability_finding) do
        create(:vulnerabilities_finding, project: project, uuid: sast_findings.first.uuid)
      end

      it 'returns no merge requests' do
        expect(get_findings_from_response(subject).first['mergeRequest']).to be_nil
      end
    end

    context 'when the security finding has a related vulnerability finding' do
      let_it_be(:vulnerability_finding) do
        create(:vulnerabilities_finding, project: project, uuid: sast_findings.first.uuid)
      end

      let_it_be(:mr_feedback) do
        create(:vulnerability_feedback, :merge_request, project: project, finding_uuid: vulnerability_finding.uuid)
      end

      let(:mr_description) { get_findings_from_response(subject).first['mergeRequest']['description'] }

      it 'returns the merge request for the security findings' do
        expect(mr_description).to eq(mr_feedback.merge_request.description)
      end
    end

    context 'when multiple findings are detected' do
      let(:query_for_test) do
        %(
          uuid
          mergeRequest {
            targetBranch
          }
        )
      end

      let_it_be(:existing_feedback) do
        create(
          :vulnerability_feedback,
          :merge_request,
          project: project,
          finding: create(:vulnerabilities_finding, project: project, uuid: sast_findings.first.uuid),
          merge_request: create(
            :merge_request,
            :unique_author,
            source_project: project,
            target_branch: "example-#{sast_findings.first.id}"
          )
        )
      end

      let!(:initial_query) do
        # Warm up table schema and other data (e.g. SAML providers, license)
        run_with_clean_state(sast_query, context: { current_user: user })

        ActiveRecord::QueryRecorder.new do
          run_with_clean_state(sast_query, context: { current_user: user })
        end
      end

      before do
        sast_findings[1..].each do |sast_finding|
          create(
            :vulnerability_feedback,
            :merge_request,
            project: project,
            finding: create(:vulnerabilities_finding, project: project, uuid: sast_finding.uuid),
            merge_request: create(
              :merge_request,
              :unique_author,
              source_project: project,
              target_branch: "example-#{sast_finding.id}"
            )
          )
        end
      end

      subject(:results) { run_with_clean_state(sast_query, context: { current_user: user }) }

      it 'avoids N+1 queries' do
        expect { results }.not_to exceed_query_limit(initial_query)
      end

      it 'loads the minimum amount of data' do
        query = ActiveRecord::QueryRecorder.new { results }
        expect(query.occurrences_starting_with("SELECT \"merge_requests\"").values.sum).to eq(1)
      end

      it 'loads each merge request' do
        branches = results
          .dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')
          .map { |node| node.dig('mergeRequest', 'targetBranch') }
        expect(branches).to match_array(sast_findings.map { |x| "example-#{x.id}" })
      end

      it 'loads each finding id' do
        finding_ids = results
          .dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')
          .pluck('uuid')
        expect(finding_ids).to match_array(sast_findings.map(&:uuid))
      end
    end
  end

  describe 'remediations' do
    let_it_be(:finding_data) { { remediation_byte_offsets: [{ start_byte: 3769, end_byte: 13792 }] } }

    let(:response) { GitlabSchema.execute(dep_scan_query, context: { current_user: user }) }
    let(:expected_remediation) { dep_scan_findings.flat_map(&:remediations).first.slice('summary', 'diff') }
    let(:response_remediation) { get_findings_from_response(response).second['remediations'].first }
    let(:query_for_test) do
      %(
        remediations {
          summary
          diff
        }
      )
    end

    before do
      dep_scan_findings.first.finding_data = finding_data
      dep_scan_findings.first.save!
    end

    it 'returns remediations for security findings which have one' do
      expect(response_remediation).to match(expected_remediation)
    end

    it 'responds with an empty array for security findings which have none' do
      expect(dep_scan_findings.map(&:remediations)).to include([])
    end

    context 'when a remediation does not exist for a single finding query' do
      let(:response) { GitlabSchema.execute(remediations_query, context: { current_user: user }) }
      let(:response_remediation) do
        response.dig('data', 'project', 'pipeline', 'securityReportFinding', 'remediations')
      end

      let(:remediations_query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              pipeline(iid: "#{pipeline.iid}") {
                securityReportFinding(uuid: "#{dep_scan_findings.first.uuid}") {
                  remediations {
                    summary
                    diff
                  }
                }
              }
            }
          }
        )
      end

      context 'when a vulnerability finding exists for the report finding' do
        let_it_be(:vulnerability_finding) do
          create(:vulnerabilities_finding, project: project, uuid: dep_scan_findings.first.uuid)
        end

        it 'responds with an empty array' do
          expect(response_remediation).to be_empty
        end
      end

      context 'when a vulnerability finding does not exist for the report finding' do
        it 'responds with an empty array' do
          expect(response_remediation).to be_empty
        end
      end
    end
  end

  describe 'dismissal data' do
    let(:query_for_test) do
      %(
        uuid
        dismissedAt
        dismissedBy {
          name
        }
        stateComment
        dismissalReason
      )
    end

    context 'when there is a security finding with no dismissal feedback' do
      it 'returns no dismissal data' do
        expect(get_findings_from_response(subject).first['dismissed_at']).to be_nil
      end
    end

    context 'when the security finding has a related dismissal feedback' do
      let_it_be(:sast_dismissal_feedback) do
        create(:vulnerability_feedback,
               :dismissal,
               :comment,
               author: user,
               project: project,
               pipeline: pipeline,
               finding_uuid: sast_findings.first.uuid)
      end

      let_it_be(:dep_scan_dismissal_feedback) do
        create(:vulnerability_feedback,
               :dismissal,
               :comment,
               author: user,
               project: project,
               pipeline: pipeline,
               finding_uuid: dep_scan_findings.first.uuid)
      end

      let(:response_finding) { get_findings_from_response(subject).first }
      let(:expected_response_finding) do
        {
          'uuid' => sast_dismissal_feedback.finding_uuid,
          'dismissedAt' => sast_dismissal_feedback.created_at.iso8601,
          'dismissedBy' => { 'name' => sast_dismissal_feedback.author.name },
          'stateComment' => sast_dismissal_feedback.comment,
          'dismissalReason' => sast_dismissal_feedback.dismissal_reason.upcase
        }
      end

      it 'returns the dismissal data for the security findings' do
        expect(response_finding).to eq(expected_response_finding)
      end

      it 'avoids N+1 queries' do
        # Warm up table schema and other data (e.g. SAML providers, license)
        run_with_clean_state(sast_query, context: { current_user: user })

        initial_query =
          ActiveRecord::QueryRecorder.new { run_with_clean_state(dep_scan_query, context: { current_user: user }) }

        expect { run_with_clean_state(sast_query, context: { current_user: user }) }
          .not_to exceed_query_limit(initial_query)
      end

      context 'when the number of requested dismissal fields changes' do
        let(:reduced_query) do
          %(
            query {
              project(fullPath: "#{project.full_path}") {
                pipeline(iid: "#{pipeline.iid}") {
                  securityReportFindings(reportType: ["sast"]) {
                    nodes {
                      uuid
                      dismissedBy {
                        name
                      }
                    }
                  }
                }
              }
            }
          )
        end

        it 'does not increase the number of queries' do
          # Warm up table schema and other data (e.g. SAML providers, license)
          run_with_clean_state(sast_query, context: { current_user: user })

          initial_query =
            ActiveRecord::QueryRecorder.new { run_with_clean_state(reduced_query, context: { current_user: user }) }

          expect { run_with_clean_state(sast_query, context: { current_user: user }) }
            .not_to exceed_query_limit(initial_query)
        end
      end
    end
  end

  def create_findings(scan, report, artifact)
    content = File.read(artifact.file.path)
    ::Gitlab::Ci::Parsers.parsers[report.type].parse!(content, report)
    report.merge!(report)
    report.findings.map do |finding|
      create(:security_finding, uuid: finding.uuid, scan: scan, deduplicated: true)
    end
  end

  def get_findings_from_response(response)
    response.dig('data', 'project', 'pipeline', 'securityReportFindings', 'nodes')
  end

  def get_issues_from_findings(findings)
    findings.pluck('issueLinks').compact.pluck('nodes').flatten
  end
  alias_method :get_issues_from_vulnerabilities, :get_issues_from_findings

  def get_merge_requests_from_query
    response = run_with_clean_state(sast_query, context: { current_user: user })
    findings = get_findings_from_response(response)
    findings.pluck('mergeRequest').compact
  end
end
