# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Creating an Issue from a Security::Finding', feature_category: :vulnerability_management do
  include GraphqlHelpers

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success) }

  let_it_be(:build_sast) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:artifact_sast) do
    create(:ee_ci_job_artifact, :sast_with_signatures_and_vulnerability_flags, job: build_sast)
  end

  let_it_be(:report) { create(:ci_reports_security_report, pipeline: pipeline, type: :sast) }
  let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :sast, build: artifact_sast.job) }

  let_it_be(:security_findings) { [] }

  before_all do
    sast_content = File.read(artifact_sast.file.path)
    Gitlab::Ci::Parsers::Security::Sast.parse!(sast_content, report)
    report.merge!(report)
    security_findings.push(*insert_security_findings)
  end

  let(:security_finding) { security_findings.first }
  let(:security_finding_uuid) { security_finding.uuid }
  let(:project_gid) { GitlabSchema.id_from_object(project) }

  let(:mutation_name) { :security_finding_create_issue }
  let(:mutation) do
    graphql_mutation(
      mutation_name,
      project: project_gid,
      uuid: security_finding_uuid
    )
  end

  context 'when deprecate_vulnerabilities_feedback feature flag is disabled' do
    before do
      project.add_developer(current_user)
      stub_feature_flags(deprecate_vulnerabilities_feedback: false)
    end

    it 'returns a successful response with a blank issue' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_mutation_response(mutation_name)['errors']).to match_array(['Feature flag disabled'])
    end
  end

  context 'when deprecate_vulnerabilities_feedback feature flag is enabled' do
    context 'when the user does not have permission' do
      it_behaves_like 'a mutation that returns a top-level access error'

      it 'does not create a new vulnerability' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Vulnerability, :count)
      end

      it 'does not create a new issue' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Issue, :count)
      end

      it 'does not create a new issue link' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change(Vulnerabilities::IssueLink, :count)
      end
    end

    context 'when the user has permission' do
      before do
        project.add_developer(current_user)
      end

      context 'with valid parameters' do
        it 'returns a successful response' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_mutation_response(mutation_name)['errors']).to be_empty
        end

        it 'does create a new vulnerability' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(Vulnerability, :count).by(1)
        end

        it 'does create a new issue' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(Issue, :count).by(1)
        end

        it 'does create a new issue link' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change(Vulnerabilities::IssueLink, :count).by(1)
        end
      end

      context 'when security_dashboard is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
      end
    end
  end

  def insert_security_findings
    report.findings.map do |finding|
      create(:security_finding,
             severity: finding.severity,
             confidence: finding.confidence,
             uuid: finding.uuid,
             scan: scan)
    end
  end
end
