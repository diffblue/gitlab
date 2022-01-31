# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Read, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
  end

  describe 'validations' do
    let!(:vulnerability_read) { create(:vulnerability_read) }

    it { is_expected.to validate_presence_of(:vulnerability_id) }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:scanner_id) }
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:state) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_length_of(:location_image).is_at_most(2048) }

    it { is_expected.to validate_uniqueness_of(:vulnerability_id) }
    it { is_expected.to validate_uniqueness_of(:uuid).case_insensitive }

    it { is_expected.to allow_value(true).for(:has_issues) }
    it { is_expected.to allow_value(false).for(:has_issues) }
    it { is_expected.not_to allow_value(nil).for(:has_issues) }

    it { is_expected.to allow_value(true).for(:resolved_on_default_branch) }
    it { is_expected.to allow_value(false).for(:resolved_on_default_branch) }
    it { is_expected.not_to allow_value(nil).for(:resolved_on_default_branch) }
  end

  describe 'triggers' do
    let(:namespace) { create(:namespace) }
    let(:user) { create(:user) }
    let(:project) { create(:project, namespace: namespace) }
    let(:issue) { create(:issue, project: project) }
    let(:scanner) { create(:vulnerabilities_scanner, project: project) }
    let(:identifier) { create(:vulnerabilities_identifier, project: project) }
    let(:vulnerability) { create_vulnerability }
    let(:vulnerability2) { create_vulnerability }
    let(:finding) { create_finding(primary_identifier: identifier) }

    describe 'trigger on vulnerability_occurrences insert' do
      context 'when vulnerability_id is set' do
        it 'creates a new vulnerability_reads row' do
          expect do
            create_finding(vulnerability: vulnerability2)
          end.to change { Vulnerabilities::Read.count }.from(0).to(1)
        end
      end

      context 'when vulnerability_id is not set' do
        it 'does not create a new vulnerability_reads row' do
          expect do
            create_finding
          end.not_to change { Vulnerabilities::Read.count }
        end
      end
    end

    describe 'trigger on vulnerability_occurrences update' do
      context 'when vulnerability_id is updated' do
        it 'creates a new vulnerability_reads row' do
          expect do
            finding.update!(vulnerability_id: vulnerability.id)
          end.to change { Vulnerabilities::Read.count }.from(0).to(1)
        end
      end

      context 'when vulnerability_id is not updated' do
        it 'does not create a new vulnerability_reads row' do
          finding.update!(vulnerability_id: nil)

          expect do
            finding.update!(location: '')
          end.not_to change { Vulnerabilities::Read.count }
        end
      end
    end

    describe 'trigger on vulnerability_occurrences location update' do
      context 'when image is updated' do
        it 'updates location_image in vulnerability_reads' do
          finding = create_finding(vulnerability: vulnerability, report_type: 7, location: { "image" => "alpine:3.4" })

          expect do
            finding.update!(location: { "image" => "alpine:4" })
          end.to change { Vulnerabilities::Read.first.location_image }.from("alpine:3.4").to("alpine:4")
        end
      end

      context 'when agent_id is updated' do
        it 'updates cluster_agent_id in vulnerability_reads' do
          finding = create_finding(vulnerability: vulnerability, report_type: 7, location: { "image" => "alpine:3.4" })

          expect do
            finding.update!(location: { "kubernetes_resource" => { "agent_id" => "1234" } })
          end.to change { Vulnerabilities::Read.first.cluster_agent_id }.from(nil).to("1234")
        end
      end

      context 'when image or agent_id is not updated' do
        it 'does not update location_image or cluster_agent_id in vulnerability_reads' do
          finding = create_finding(
            vulnerability: vulnerability,
            report_type: 7,
            location: { "image" => "alpine:3.4", "kubernetes_resource" => { "agent_id" => "1234" } }
          )

          expect do
            finding.update!(project_fingerprint: "123qweasdzx")
          end.not_to change { Vulnerabilities::Read.first.location_image }
        end
      end
    end

    describe 'trigger on vulnerabilities update' do
      before do
        create_finding(vulnerability: vulnerability, report_type: 7)
      end

      context 'when vulnerability attributes are updated' do
        it 'updates vulnerability attributes in vulnerability_reads' do
          expect do
            vulnerability.update!(severity: 6)
          end.to change { Vulnerabilities::Read.first.severity }.from("critical").to("high")
        end
      end

      context 'when vulnerability attributes are not updated' do
        it 'does not update vulnerability attributes in vulnerability_reads' do
          expect do
            vulnerability.update!(title: "New vulnerability")
          end.not_to change { Vulnerabilities::Read.first }
        end
      end
    end

    describe 'trigger on vulnerabilities_issue_link' do
      context 'on insert' do
        before do
          create_finding(vulnerability: vulnerability, report_type: 7)
        end

        it 'updates has_issues in vulnerability_reads' do
          expect do
            create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
          end.to change { Vulnerabilities::Read.first.has_issues }.from(false).to(true)
        end
      end

      context 'on delete' do
        before do
          create_finding(vulnerability: vulnerability, report_type: 7)
        end

        let(:issue2) { create(:issue, project: project) }

        it 'does not change has_issues when there exists another issue' do
          issue_link1 = create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
          create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue2)

          expect do
            issue_link1.delete
          end.not_to change { Vulnerabilities::Read.first.has_issues }
        end

        it 'unsets has_issues when all issues are deleted' do
          issue_link1 = create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)
          issue_link2 = create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue2)

          expect do
            issue_link1.delete
            issue_link2.delete
          end.to change { Vulnerabilities::Read.first.has_issues }.from(true).to(false)
        end
      end
    end
  end

  private

  def create_vulnerability(severity: 7, confidence: 7, report_type: 0)
    create(:vulnerability,
      project: project,
      author: user,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  # rubocop:disable Metrics/ParameterLists
  def create_finding(
    vulnerability: nil, primary_identifier: identifier, severity: 7, confidence: 7, report_type: 0,
    project_fingerprint: '123qweasdzxc', location: { "image" => "alpine:3.4" }, location_fingerprint: 'test',
    metadata_version: 'test', raw_metadata: 'test', uuid: SecureRandom.uuid)
    create(:vulnerabilities_finding,
      vulnerability: vulnerability,
      project: project,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner: scanner,
      primary_identifier: primary_identifier,
      location: location,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    )
  end
  # rubocop:enable Metrics/ParameterLists
end
