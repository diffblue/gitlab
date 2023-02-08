# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::SecurityFinding::CreateIssueService, '#execute',
feature_category: :vulnerability_management do
  before do
    stub_licensed_features(security_dashboard: true)
    project.add_developer(user)
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success) }

  let_it_be(:build_sast) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:artifact_sast) do
    create(:ee_ci_job_artifact, :sast_with_signatures_and_vulnerability_flags,
           job: build_sast)
  end

  let_it_be(:report_sast) { create(:ci_reports_security_report, pipeline: pipeline, type: :sast) }
  let_it_be(:scan_sast) { create(:security_scan, :latest_successful, scan_type: :sast, build: artifact_sast.job) }

  let_it_be(:user) { create(:user) }
  let_it_be(:sast_security_findings) { [] }

  before_all do
    sast_content = File.read(artifact_sast.file.path)
    Gitlab::Ci::Parsers::Security::Sast.parse!(sast_content, report_sast)
    report_sast.merge!(report_sast)
    sast_security_findings.push(*insert_security_findings(report_sast, scan_sast))
  end

  let(:security_finding) { sast_security_findings.first }
  let(:security_finding_uuid) { security_finding.uuid }
  let(:params) { { security_finding_uuid: security_finding_uuid } }

  let(:subject) { described_class.new(project: project, current_user: user, params: params).execute }

  context 'when user does not have permission to read_security_resource' do
    let(:user_not_member_of_project) { create(:user) }
    let(:subject) do
      described_class.new(project: project,
                          current_user: user_not_member_of_project,
                          params: params).execute
    end

    it 'raises an error' do
      expect { subject }.to raise_error Gitlab::Access::AccessDeniedError
    end
  end

  context 'when user does not have permission to create issue' do
    before do
      allow_next_instance_of(Issues::CreateFromVulnerabilityService) do |instance|
        allow(instance).to receive(:can?).with(user, :create_issue, project).and_return(false)
      end
    end

    it 'propagates the error' do
      expect(subject).not_to be_success
      expect(subject.message).to eq('User is not permitted to create issue')
    end
  end

  context 'when there is no vulnerability finding and vulnerability for the security finding' do
    it 'does create a new Vulnerability' do
      expect { subject }.to change { project.vulnerabilities.count }.by(1)
    end

    it 'does create a new Issue' do
      expect { subject }.to change(Issue, :count).by(1)
    end

    it 'does create a new IssueLink' do
      expect { subject }.to change { Vulnerabilities::IssueLink.count }.by(1)
    end
  end

  context 'when there is an existing vulnerability finding and vulnerability for the security finding' do
    let_it_be(:finding) do
      create(:vulnerabilities_finding, :detected,
        report_type: :sast, project: project, uuid: sast_security_findings.first.uuid)
    end

    let_it_be(:vulnerability) do
      create(:vulnerability, report_type: :sast, project: project, findings: [finding])
    end

    it 'does not create a new Vulnerability' do
      expect { subject }.not_to change { project.vulnerabilities.count }
    end

    it 'does create a new Issue' do
      expect { subject }.to change(Issue, :count).by(1)
    end

    it 'does create a new IssueLink' do
      expect { subject }.to change { Vulnerabilities::IssueLink.count }.by(1)
    end
  end

  shared_examples 'an error occurs' do
    it 'propagates the error' do
      expect(subject).not_to be_success
      expect(subject.message).to eq(error_message)
    end

    it 'does not create a new Vulnerability' do
      expect { subject }.not_to change { project.vulnerabilities.count }
    end

    it 'does not create a new Issue' do
      expect { subject }.not_to change(Issue, :count)
    end

    it 'does not create a new IssueLink' do
      expect { subject }.not_to change { Vulnerabilities::IssueLink.count }
    end
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

  context 'when a error occurs during the issue creation' do
    let(:error_message) { 'Invalid vulnerability category' }
    let(:error_response) { ServiceResponse.error(message: error_message) }

    before do
      allow_next_instance_of(Issues::CreateFromVulnerabilityService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it_behaves_like 'an error occurs'
  end

  context 'when a error occurs during the issue link creation' do
    let(:error_message) { 'Vulnerability already has a "created" issue link' }
    let(:error_response) { ServiceResponse.error(message: error_message) }

    before do
      allow_next_instance_of(VulnerabilityIssueLinks::CreateService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it_behaves_like 'an error occurs'
  end

  def insert_security_findings(report, scan)
    report.findings.map do |finding|
      create(:security_finding,
             severity: finding.severity,
             confidence: finding.confidence,
             uuid: finding.uuid,
             scan: scan)
    end
  end
end
