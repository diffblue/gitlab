# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::SecurityFinding::CreateMergeRequestService, '#execute',
feature_category: :vulnerability_management do
  let_it_be(:remediations_folder) { Rails.root.join('ee/spec/fixtures/security_reports/remediations') }
  let(:security_finding) { security_findings.first }
  let(:security_finding_uuid) { security_finding.uuid }
  let(:vulnerability_data) { Gitlab::Json.parse(report.findings.last.raw_metadata).with_indifferent_access }
  let(:params) { { security_finding_uuid: security_finding_uuid, vulnerability_data: vulnerability_data } }
  let_it_be(:yarn_lock_content) { File.read(File.join(remediations_folder, "yarn.lock")) }
  let_it_be(:remediation_patch_content) { File.read(File.join(remediations_folder, "remediation.patch")) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) do
    create(:project, :custom_repo, namespace: group, files: { 'yarn.lock' => yarn_lock_content })
  end

  let_it_be(:pipeline) { create(:ci_pipeline, :success) }

  let_it_be(:build) { create(:ci_build, :success, name: 'dependency_scanning', pipeline: pipeline) }
  let_it_be(:artifact) do
    create(:ee_ci_job_artifact, :dependency_scanning_remediation, job: build)
  end

  let_it_be(:report) { create(:ci_reports_security_report, pipeline: pipeline, type: :dependency_scanning) }
  let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :dependency_scanning, build: artifact.job) }

  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:security_findings) { [] }

  subject { described_class.new(project: project, current_user: current_user, params: params).execute }

  before do
    stub_licensed_features(security_dashboard: true)
    group.add_developer(user)
  end

  before_all do
    content = File.read(artifact.file.path)
    Gitlab::Ci::Parsers::Security::DependencyScanning.parse!(content, report)
    report.merge!(report)

    finding = report.findings.find do |finding|
      finding.cve == 'yarn.lock:saml2-js:gemnasium:9952e574-7b5b-46fa-a270-aeb694198a98'
    end

    security_finding = create(:security_finding,
                              severity: finding.severity,
                              confidence: finding.confidence,
                              uuid: finding.uuid,
                              scan: scan)

    security_findings.push(security_finding)
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
    let_it_be(:finding) do
      create(:vulnerabilities_finding, :detected,
             report_type: :dependency_scanning, project: project, uuid: security_findings.first.uuid)
    end

    let_it_be(:vulnerability) do
      create(:vulnerability, report_type: :dependency_scanning, project: project, findings: [finding])
    end

    it 'does not create a new Vulnerability, but creates a new MergeRequest, and a MergeRequestLink' do
      expect { subject }.to change {
        project.vulnerabilities.count
      }.by(0)
       .and(change(MergeRequest, :count).by(1))
       .and(change(Vulnerabilities::MergeRequestLink, :count).by(1))
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
