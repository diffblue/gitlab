# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a Merge Request from a Security::Finding', feature_category: :vulnerability_management do
  include_context 'with dependency scanning security report findings'
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let_it_be(:scan) do
    create(
      :security_scan,
      :latest_successful,
      scan_type: :dependency_scanning,
      pipeline: pipeline,
      build: artifact.job
    )
  end

  let_it_be(:security_finding) do
    create(
      :security_finding,
      severity: report_finding.severity,
      confidence: report_finding.confidence,
      uuid: report_finding.uuid,
      scan: scan
    )
  end

  let_it_be_with_reload(:vulnerability_finding) do
    create(
      :vulnerabilities_finding_with_remediation, :with_remediation, :identifier, :detected,
      uuid: report_finding.uuid,
      project: project,
      report_type: :dependency_scanning,
      summary: 'Test remediation',
      raw_metadata: report_finding.raw_metadata
    )
  end

  let_it_be(:vulnerability_pipeline) do
    create(:vulnerabilities_finding_pipeline, finding: vulnerability_finding, pipeline: pipeline)
  end

  let(:mutation_name) { :security_finding_create_merge_request }
  let(:mutation) { graphql_mutation(mutation_name, uuid: security_finding.uuid) }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create a merge request' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { security_finding.project.merge_requests.count }
    end
  end

  context 'when the user has permission' do
    before do
      allow_next_instance_of(Commits::CommitPatchService) do |service|
        allow(service).to receive(:execute).and_return({ status: :success })
      end

      security_finding.project.add_maintainer(current_user)
    end

    context 'with valid parameters' do
      it 'returns a successful response' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_mutation_response(mutation_name)['errors']).to be_empty
      end

      it 'creates a new merge request' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { project.merge_requests.count }.by(1)
      end
    end

    context 'when security_dashboard is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it_behaves_like 'a mutation that returns top-level errors', errors: [
        [
          "The resource that you are attempting to access does not exist or",
          "you don't have permission to perform this action"
        ].join(" ")
      ]
    end
  end
end
