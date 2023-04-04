# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::SecurityFinding::CreateMergeRequestService, '#execute', feature_category: :vulnerability_management do
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

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }

  subject do
    described_class.new(project: project, current_user: current_user, params: {
      security_finding: security_finding
    }).execute
  end

  before do
    stub_licensed_features(security_dashboard: true)
    group.add_developer(user)
  end

  context 'when user does not have permission to read_security_resource' do
    let_it_be(:user_not_member_of_project) { create(:user) }
    let_it_be(:current_user) { user_not_member_of_project }

    it 'raises an error' do
      expect { subject }.to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when user does not have permission to create merge request' do
    before do
      allow_next_instance_of(MergeRequests::CreateFromVulnerabilityDataService) do |instance|
        allow(instance).to receive(:can?).with(user, :create_merge_request_in, project).and_return(false)
      end
    end

    it 'propagates the error' do
      expect(subject).not_to be_success
      expect(subject.message).to eq('User is not permitted to create merge request')
    end
  end

  context 'when there is an existing vulnerability for the security finding' do
    let_it_be(:vulnerability_finding) do
      create(
        :vulnerabilities_finding_with_remediation,
        :with_remediation,
        :identifier,
        :detected,
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

    let_it_be(:vulnerability) do
      create(:vulnerability, report_type: :dependency_scanning, project: project, findings: [vulnerability_finding])
    end

    before do
      allow_next_instance_of(Commits::CommitPatchService) do |service|
        allow(service).to receive(:execute).and_return({ status: :success })
      end
    end

    it 'does not create a new Vulnerability, but creates a new MergeRequest, and a MergeRequestLink' do
      expect { subject }.to change {
        project.vulnerabilities.count
      }.by(0)
       .and(change(MergeRequest, :count).by(1))
       .and(change(Vulnerabilities::MergeRequestLink, :count).by(1))
    end

    it 'returns a successful response' do
      response = subject
      expect(response.message).to be_blank
      expect(response.payload[:merge_request]).to be_present
    end
  end

  context 'when there is no vulnerability for the security finding' do
    it 'does create a new Vulnerability, MergeRequest,and MergeRequestLink' do
      expect { subject }.to change {
        project.vulnerabilities.count
      }.by(1)
       .and(change(MergeRequest, :count).by(1))
       .and(change(Vulnerabilities::MergeRequestLink, :count).by(1))
    end
  end

  shared_examples 'an error occurs' do
    it 'propagates the error' do
      expect(subject).not_to be_success
      expect(subject.message).to eq(error_message)
    end

    it 'does not create a new Vulnerability, MergeRequest, and MergeRequestLink' do
      expect { subject }.to change {
        project.vulnerabilities.count
      }.by(0)
       .and(change(Vulnerabilities::MergeRequestLink, :count).by(0))
       .and(change(Vulnerabilities::MergeRequestLink, :count).by(0))
    end
  end

  context 'when a error occurs during the merge request creation' do
    let(:error_message) { 'Invalid vulnerability category' }
    let(:error_response) { ServiceResponse.error(message: error_message) }

    before do
      allow_next_instance_of(MergeRequests::CreateFromVulnerabilityDataService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it_behaves_like 'an error occurs'
  end

  context 'when a error occurs during the vulnerability creation' do
    let(:error_message) { 'Security Finding not found' }
    let(:error_response) { ServiceResponse.error(message: error_message) }

    before do
      allow_next_instance_of(Vulnerabilities::FindOrCreateFromSecurityFindingService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it_behaves_like 'an error occurs'
  end

  context 'when a error occurs during the merge link creation' do
    let(:error_message) { 'Merge request is already linked to this vulnerability' }
    let(:error_response) { ServiceResponse.error(message: error_message) }

    before do
      allow_next_instance_of(VulnerabilityMergeRequestLinks::CreateService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it_behaves_like 'an error occurs'
  end
end
