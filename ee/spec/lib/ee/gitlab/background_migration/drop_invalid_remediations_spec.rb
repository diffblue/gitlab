# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DropInvalidRemediations, schema: 20211118194239 do
  let(:remediations) { table(:vulnerability_findings_remediations) }

  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 14219619, namespace_id: namespace.id) }
  let(:scanners) { table(:vulnerability_scanners) }
  let!(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      id: 1244459,
      project_id: project.id,
      external_type: 'vulnerability-identifier',
      external_id: 'vulnerability-identifier',
      fingerprint: '0a203e8cd5260a1948edbedc76c7cb91ad6a2e45',
      name: 'vulnerability identifier')
  end

  let!(:vulnerability_1) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:vulnerability_2) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:corrupt_finding_1) do
    create_finding!(
      id: 5606961,
      uuid: "bd95c085-71aa-51d7-9bb6-08ae669c262e",
      vulnerability_id: vulnerability_1.id,
      report_type: 0,
      location_fingerprint: '00049d5119c2cb3bfb3d1ee1f6e031fe925aed74',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner.id,
      project_id: project.id,
      raw_metadata: metadata(true)
    )
  end

  let!(:finding_2) do
    create_finding!(
      id: 8765432,
      uuid: "5b714f58-1176-5b26-8fd5-e11dfcb031b5",
      vulnerability_id: vulnerability_2.id,
      report_type: 0,
      location_fingerprint: '00049d5119c2cb3bfb3d1ee1f6e031fe925aed75',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner.id,
      project_id: project.id,
      raw_metadata: metadata(false)
    )
  end

  let!(:remediation1) { remediations.create!(vulnerability_occurrence_id: corrupt_finding_1.id) }
  let!(:remediation2) { remediations.create!(vulnerability_occurrence_id: finding_2.id) }

  context 'corresponding vuln has a remediation provided' do
    it 'only deletes the finding_remediations without a remediation' do
      expect { described_class.new.perform(remediation1.id, remediation2.id) }.to change { remediations.count }.from(2).to(1)
    end
  end

  private

  def create_vulnerability!(project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0)
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def create_finding!(
    id: nil,
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:,
                      name: "test", severity: 7, confidence: 7, report_type: 0,
                      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
                      metadata_version: 'test', raw_metadata: 'test', uuid: SecureRandom.uuid)
    vulnerability_findings.create!(
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: name,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner_id: scanner.id,
      primary_identifier_id: vulnerability_identifier.id,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil, created_at: Time.zone.now, confirmed_at: Time.zone.now)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at
    )
  end

  def metadata(corrupt)
    remediations = if corrupt
                     [nil]
                   else
                     [
                       {
                         summary: 'summary',
                         diff: Base64.encode64("This ain't a diff")
                       }
                     ]
                   end

    { remediations: remediations }.to_json
  end
end
