# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::CreateFromSecurityFindingService, '#execute' do
  before do
    stub_licensed_features(security_dashboard: true)
    project.add_developer(user)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:build) { create(:ci_build, :success, name: 'dast', pipeline: pipeline) }
  let_it_be(:artifact) { create(:ee_ci_job_artifact, :dast, job: build) }
  let_it_be(:report) { create(:ci_reports_security_report, pipeline: pipeline, type: :dast) }
  let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :dast, build: artifact.job) }
  let_it_be(:security_findings) { [] }
  let(:state) { 'confirmed' }
  let(:params) { { security_finding_uuid: security_finding_uuid } }
  let(:service) do
    Vulnerabilities::CreateFromSecurityFindingService.new(
      project: project,
      current_user: user,
      params: params,
      state: state,
      present_on_default_branch: present_on_default_branch
    )
  end

  let(:present_on_default_branch) { false }

  before_all do
    dast_content = File.read(artifact.file.path)
    Gitlab::Ci::Parsers::Security::Dast.parse!(dast_content, report)
    report.merge!(report)

    security_findings.push(*insert_security_findings)
  end

  let_it_be(:security_finding_uuid) { security_findings.first.uuid }

  subject { service.execute }

  context 'when there is an existing vulnerability for the security finding' do
    let_it_be(:security_finding) { create(:security_finding) }
    let_it_be(:vulnerability) do
      create(:vulnerability, project: project,
             findings: [create(:vulnerabilities_finding, uuid: security_finding_uuid)])
    end

    it 'does not creates a new Vulnerability' do
      expect { subject }.not_to change(Vulnerability, :count)
    end

    it 'returns the existing Vulnerability' do
      expect(subject.success?).to be_truthy
      expect(subject.payload[:vulnerability].id).to eq(vulnerability.id)
    end
  end

  context 'when there is no vulnerability for the security finding' do
    let_it_be(:security_finding_uuid) { security_findings.last.uuid }

    it 'creates a new Vulnerability' do
      expect { subject }.to change(Vulnerability, :count).by(1)
    end

    it 'returns a vulnerability with the given state and present_on_default_branch' do
      expect(subject.success?).to be_truthy
      expect(subject.payload[:vulnerability].state).to eq(state)
      expect(subject.payload[:vulnerability].present_on_default_branch).to eq(present_on_default_branch)
    end
  end

  context 'when there is a error during the vulnerability_finding creation' do
    let_it_be(:security_finding_uuid) { 'invalid-security-finding-uuid' }

    it 'returns an error' do
      expect(subject.error?).to be_truthy
      expect(subject[:message]).to eq('Security Finding not found')
    end
  end

  context 'when security dashboard feature is disabled' do
    before do
      stub_licensed_features(security_dashboard: false)
    end

    it 'raises an "access denied" error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
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
