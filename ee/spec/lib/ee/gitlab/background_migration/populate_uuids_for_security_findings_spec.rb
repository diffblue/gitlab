# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings,
               :suppress_gitlab_schemas_validate_connection, schema: 20211108211434 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:ci_builds) { table(:ci_builds) }
  let(:ci_artifacts) { table(:ci_job_artifacts) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:security_scans) { table(:security_scans) }
  let(:security_findings) { table(:security_findings) }
  let(:vulnerability_feedback) { table(:vulnerability_feedback) }

  let(:scan_types) { described_class::SecurityScan.scan_types }
  let(:file_types) { described_class::Artifact.file_types }
  let(:categories) { { sast: 0, dast: 3 } }
  let(:fingerprint_1) { Digest::SHA1.hexdigest(SecureRandom.uuid) }
  let(:fingerprint_2) { Digest::SHA1.hexdigest(SecureRandom.uuid) }
  let(:fingerprint_3) { Digest::SHA1.hexdigest(SecureRandom.uuid) }
  let(:fingerprint_4) { Digest::SHA1.hexdigest(SecureRandom.uuid) }

  let(:user) { users.create!(email: 'test@gitlab.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org', type: Namespaces::UserNamespace.sti_name) }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:ci_pipeline) { ci_pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: 'success') }
  let(:ci_build_1) { ci_builds.create!(commit_id: ci_pipeline.id, retried: false, type: 'Ci::Build') }
  let(:ci_build_2) { ci_builds.create!(commit_id: ci_pipeline.id, retried: false, type: 'Ci::Build') }
  let(:ci_build_3) { ci_builds.create!(commit_id: ci_pipeline.id, retried: false, type: 'Ci::Build') }
  let(:ci_artifact_1) { ci_artifacts.create!(project_id: project.id, job_id: ci_build_1.id, file_type: file_types[:sast], file_format: 1) }
  let(:ci_artifact_2) { ci_artifacts.create!(project_id: project.id, job_id: ci_build_2.id, file_type: file_types[:dast], file_format: 1) }
  let(:ci_artifact_3) { ci_artifacts.create!(project_id: project.id, job_id: ci_build_3.id, file_type: file_types[:dast], file_format: 1, expire_at: 1.day.ago) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'bandit', name: 'Bandit') }
  let(:security_scan_1) { security_scans.create!(build_id: ci_build_1.id, scan_type: scan_types[:sast]) }
  let(:security_scan_2) { security_scans.create!(build_id: ci_build_2.id, scan_type: scan_types[:dast]) }
  let(:security_scan_3) { security_scans.create!(build_id: ci_build_3.id, scan_type: scan_types[:dast]) }
  let(:sast_file) { fixture_file_upload(Rails.root.join('spec/fixtures/security_reports/master/gl-sast-report.json'), 'application/json') }
  let(:dast_file) { fixture_file_upload(Rails.root.join('ee/spec/fixtures/security_reports/master/gl-dast-report.json'), 'application/json') }

  let!(:finding_1) { security_findings.create!(scan_id: security_scan_1.id, scanner_id: scanner.id, severity: 0, confidence: 0, position: 0, project_fingerprint: fingerprint_1) }
  let!(:finding_2) { security_findings.create!(scan_id: security_scan_1.id, scanner_id: scanner.id, severity: 0, confidence: 0, position: 1, project_fingerprint: fingerprint_2) }
  let!(:finding_3) { security_findings.create!(scan_id: security_scan_2.id, scanner_id: scanner.id, severity: 0, confidence: 0, position: 0, project_fingerprint: fingerprint_3) }
  let!(:finding_4) { security_findings.create!(scan_id: security_scan_3.id, scanner_id: scanner.id, severity: 0, confidence: 0, position: 0, project_fingerprint: fingerprint_4) }
  let!(:feedback_1) { vulnerability_feedback.create!(project_fingerprint: fingerprint_1, category: categories[:sast], project_id: project.id, author_id: user.id, feedback_type: 0) }
  let!(:feedback_2) { vulnerability_feedback.create!(project_fingerprint: fingerprint_2, category: categories[:sast], project_id: project.id, author_id: user.id, feedback_type: 0) }
  let!(:feedback_3) { vulnerability_feedback.create!(project_fingerprint: fingerprint_3, category: categories[:dast], project_id: project.id, author_id: user.id, feedback_type: 0, finding_uuid: SecureRandom.uuid) }

  before do
    described_class::Artifact.find(ci_artifact_1.id).update!(file: sast_file)
    described_class::Artifact.find(ci_artifact_2.id).update!(file: dast_file)
    described_class::Artifact.find(ci_artifact_3.id).update!(file: dast_file)
  end

  describe '#perform' do
    subject(:populate_uuids) { described_class.new.perform(security_scan_1.id, security_scan_2.id, security_scan_3.id) }

    it 'sets the `uuid` of findings' do
      expect { populate_uuids }.to change { finding_1.reload.uuid }.from(nil)
                               .and change { finding_2.reload.uuid }.from(nil)
                               .and change { finding_3.reload.uuid }.from(nil)
    end

    it 'removes the uncoverable findings' do
      expect { populate_uuids }.to change { described_class::SecurityFinding.find_by(id: finding_4.id) }.to(nil)
    end

    it 'sets the `finding_uuid` attribute of existing feedback records' do
      expect { populate_uuids }.to change { feedback_1.reload.finding_uuid }.from(nil)
                               .and change { feedback_2.reload.finding_uuid }.from(nil)
                               .and not_change { feedback_3.reload.finding_uuid }
    end
  end
end
