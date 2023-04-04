# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Security::Finding::CreateMergeRequest, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    include_context 'with dependency scanning security report findings'

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

    subject(:execute) { mutation.resolve(uuid: security_finding.uuid) }

    context 'when a user is not logged in' do
      let(:current_user) { nil }

      it 'raises an error' do
        expect { execute }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the current user does not have access to the project' do
      let_it_be(:current_user) { create(:user) }

      it 'raises an error' do
        expect { execute }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the current user is a maintainer of the project' do
      let_it_be(:current_user) { create(:user) }

      before do
        stub_licensed_features(security_dashboard: true)

        allow_next_instance_of(Commits::CommitPatchService) do |service|
          allow(service).to receive(:execute).and_return({ status: :success })
        end

        project.add_maintainer(current_user)
      end

      it 'creates a new merge request' do
        expect { execute }.to change { project.merge_requests.count }.by(1)
      end

      it 'returns a valid response' do
        response = execute
        expect(response[:errors]).to be_empty
        expect(response[:merge_request]).to eq(project.merge_requests.last)
      end

      context 'when the security finding uuid is not provided' do
        it 'returns an error' do
          expect do
            mutation.resolve(uuid: nil)
          end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the security finding uuid is unknown' do
        it 'returns an error' do
          expect do
            mutation.resolve(uuid: SecureRandom.uuid)
          end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the metadata does not include a name' do
        let(:raw_metadata) { Gitlab::Json.generate(Gitlab::Json.parse(report_finding.raw_metadata).except("name")) }

        before do
          vulnerability_finding.update!(raw_metadata: raw_metadata)
        end

        it 'generates a title' do
          expect(execute[:merge_request]).to eq(project.merge_requests.last)
        end
      end
    end

    context 'when the current user is not able to create merge requests' do
      let_it_be(:current_user) { create(:user) }

      before do
        stub_licensed_features(security_dashboard: true)

        project.add_developer(current_user)
      end

      it 'returns an error' do
        response = execute
        expect(response[:errors]).not_to be_empty
        expect(response[:merge_request]).to be_blank
      end
    end
  end
end
