# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateVulnerabilitiesFromDismissalFeedback, :migration, schema: 20181228175414 do
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:vulnerability_occurrences) { table(:vulnerability_occurrences) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:feedback) { table(:vulnerability_feedback) }
  let(:namespaces) { table(:namespaces)}

  let(:severity) { ::Enums::Vulnerability.severity_levels[:unknown] }
  let(:confidence) { ::Enums::Vulnerability.confidence_levels[:medium] }
  let(:report_type) { ::Enums::Vulnerability.report_types[:sast] }

  let!(:user) { users.create!(email: 'author@example.com', username: 'author', projects_limit: 10) }
  let!(:project) { projects.create!(namespace_id: namespace.id, name: 'gitlab', path: 'gitlab') }

  let(:namespace) do
    namespaces.create!(name: 'namespace', path: '/path', description: 'description')
  end

  let(:scanner) do
    scanners.create!(project_id: project.id, external_id: 'trivy', name: 'Security Scanner')
  end

  let(:identifier) do
    identifiers.create!(project_id: project.id,
      fingerprint: 'd432c2ad2953e8bd587a3a43b3ce309b5b0154c7',
      external_type: 'SECURITY_ID',
      external_id: 'SECURITY_0',
      name: 'SECURITY_IDENTIFIER 0')
  end

  context 'vulnerability has been dismissed' do
    let!(:vulnerability) { vulnerabilities.create!(vuln_params) }
    let!(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a', status: :success, user_id: user.id) }

    let!(:vulnerability_occurrence) do
      vulnerability_occurrences.create!(
        report_type: vulnerability.report_type, name: 'finding_1',
        primary_identifier_id: identifier.id, uuid: 'abc', project_fingerprint: 'abc123',
        location_fingerprint: 'abc456', project_id: project.id, scanner_id: scanner.id, severity: severity,
        confidence: confidence, metadata_version: 'sast:1.0', raw_metadata: '{}', vulnerability_id: vulnerability.id)
    end

    let!(:dismiss_feedback) do
      feedback.create!(category: vulnerability_occurrence.report_type, feedback_type: 0,
              project_id: project.id, project_fingerprint: vulnerability_occurrence.project_fingerprint.unpack1('H*'),
              author_id: user.id)
    end

    it 'vulnerability should now have a dismissed_by_id' do
      expect(vulnerability.dismissed_by_id).to eq(nil)

      expect { described_class.new.perform(project.id) }
        .to change { vulnerability.reload.dismissed_by_id }
        .from(nil)
        .to(dismiss_feedback.author_id)
    end

    it 'vulnerability should now have a dismissed_at' do
      expect(vulnerability.dismissed_at).to eq(nil)

      expect { described_class.new.perform(project.id) }
        .to change { vulnerability.reload.dismissed_at }
        .from(nil)
        .to(dismiss_feedback.reload.created_at)
    end

    context 'project is set to be deleted' do
      let!(:project) { projects.create!(namespace_id: namespace.id, name: 'gitlab', path: 'gitlab', pending_delete: true) }

      it 'vulnerability dismissed_by_id should remain nil' do
        expect(vulnerability.dismissed_by_id).to eq(nil)

        expect { described_class.new.perform(project.id) }.not_to change { vulnerability.reload.dismissed_by_id }.from(nil)
      end

      it 'vulnerability dismissed_at should remain nil' do
        expect(vulnerability.dismissed_at).to eq(nil)

        expect { described_class.new.perform(project.id) }.not_to change { vulnerability.reload.dismissed_at }.from(nil)
      end
    end
  end

  context 'has not been dismissed' do
    let!(:vulnerability) { vulnerabilities.create!(vuln_params.merge({ state: 1 })) }

    it 'vulnerability should not have a dismissed_by_id' do
      expect(vulnerability.dismissed_by_id).to be_nil

      expect { described_class.new.perform(project.id) }.not_to change { vulnerability.reload.dismissed_by_id }.from(nil)
    end

    it 'vulnerability should not have a dismissed_at' do
      expect(vulnerability.dismissed_at).to be_nil

      expect { described_class.new.perform(project.id) }.not_to change { vulnerability.reload.dismissed_at }.from(nil)
    end
  end

  def vuln_params
    {
      title: 'title',
      state: described_class::VULNERABILITY_DISMISSED_STATE,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_id: project.id,
      author_id: user.id
    }
  end
end
