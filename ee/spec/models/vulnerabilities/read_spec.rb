# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Read, type: :model, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }

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
        subject(:create_finding_record) { create_finding(vulnerability: vulnerability2) }

        let(:created_vulnerability_read) { described_class.find_by_vulnerability_id(vulnerability2.id) }

        context 'when the related vulnerability record is not marked as `present_on_default_branch`' do
          before do
            vulnerability2.update_column(:present_on_default_branch, false)
          end

          it 'does not create a new vulnerability_reads row' do
            expect { create_finding_record }.not_to change { Vulnerabilities::Read.count }
          end
        end

        context 'when the related vulnerability record is marked as `present_on_default_branch`' do
          it 'creates a new vulnerability_reads row' do
            expect { create_finding_record }.to change { Vulnerabilities::Read.count }.from(0).to(1)
            expect(created_vulnerability_read.has_issues).to eq(false)
          end

          it 'sets has_issues to true when there are issue links' do
            create(:vulnerabilities_issue_link, vulnerability: vulnerability2)
            create_finding_record
            expect(created_vulnerability_read.has_issues).to eq(true)
          end
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
      let(:created_vulnerability_read) { described_class.find_by_vulnerability_id(vulnerability.id) }

      context 'when vulnerability_id is updated' do
        it 'creates a new vulnerability_reads row' do
          expect do
            finding.update!(vulnerability_id: vulnerability.id)
          end.to change { Vulnerabilities::Read.count }.from(0).to(1)
          expect(created_vulnerability_read.has_issues).to eq(false)
        end

        it 'sets has_issues when the vulnerability has issue links' do
          create(:vulnerabilities_issue_link, vulnerability: vulnerability)
          finding.update!(vulnerability_id: vulnerability.id)
          expect(created_vulnerability_read.has_issues).to eq(true)
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
      let!(:cluster_agent) { create(:cluster_agent, project: project) }

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
            finding.update!(location: { "kubernetes_resource" => { "agent_id" => cluster_agent.id.to_s } })
          end.to change { Vulnerabilities::Read.first.cluster_agent_id }.from(nil).to(cluster_agent.id.to_s)
        end
      end

      context 'when image or agent_id is not updated' do
        it 'does not update location_image or cluster_agent_id in vulnerability_reads' do
          finding = create_finding(
            vulnerability: vulnerability,
            report_type: 7,
            location: { "image" => "alpine:3.4", "kubernetes_resource" => { "agent_id" => cluster_agent.id.to_s } }
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

      context 'when the vulnerability is not marked as `present_on_default_branch`' do
        before do
          vulnerability.update_column(:present_on_default_branch, false)
        end

        it 'does not update vulnerability attributes in vulnerability_reads' do
          expect { vulnerability.update!(severity: :high) }.not_to change { Vulnerabilities::Read.first.severity }.from('critical')
        end
      end

      context 'when the vulnerability is marked as `present_on_default_branch`' do
        context 'when vulnerability attributes are updated' do
          it 'updates vulnerability attributes in vulnerability_reads' do
            expect do
              vulnerability.update!(severity: :high)
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
    end

    describe 'trigger_insert_vulnerability_reads_from_vulnerability' do
      subject(:update_vulnerability) { vulnerability.update!(new_vulnerability_params) }

      let(:created_vulnerability_read) { described_class.find_by_vulnerability_id(vulnerability.id) }

      before do
        vulnerability.update_column(:present_on_default_branch, false)

        create_finding(vulnerability: vulnerability)
      end

      context 'when the vulnerability does not get marked as `present_on_default_branch`' do
        let(:new_vulnerability_params) { { updated_at: Time.zone.now } }

        it 'does not create a new `vulnerability_reads` record' do
          expect { update_vulnerability }.not_to change { Vulnerabilities::Read.count }
        end
      end

      context 'when the vulnerability gets marked as `present_on_default_branch`' do
        let(:new_vulnerability_params) { { present_on_default_branch: true } }

        it 'creates a new `vulnerability_reads` record' do
          expect { update_vulnerability }.to change { Vulnerabilities::Read.count }.by(1)
          expect(created_vulnerability_read.has_issues).to eq(false)
        end

        it 'sets has_issues when the created vulnerability has issue links' do
          create(:vulnerabilities_issue_link, vulnerability: vulnerability)
          update_vulnerability
          expect(created_vulnerability_read.has_issues).to eq(true)
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

  describe '.by_scanner_ids' do
    it 'returns matching vulnerabilities' do
      vulnerability1 = create(:vulnerability, :with_finding)
      create(:vulnerability, :with_finding)

      result = described_class.by_scanner_ids(vulnerability1.finding_scanner_id)

      expect(result).to match_array([vulnerability1.vulnerability_read])
    end
  end

  describe '.for_projects' do
    let_it_be(:project_2) { create(:project) }
    let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }

    before do
      create(:vulnerability, :with_finding, project: project_2)
    end

    subject { described_class.for_projects([project.id]) }

    it 'returns vulnerability_reads related to the given project IDs' do
      is_expected.to contain_exactly(vulnerability.vulnerability_read)
    end
  end

  describe '.with_report_types' do
    let!(:dast_vulnerability) { create(:vulnerability, :with_finding, :dast) }
    let!(:dependency_scanning_vulnerability) { create(:vulnerability, :with_finding, :dependency_scanning) }
    let(:sast_vulnerability) { create(:vulnerability, :with_finding, :sast) }
    let(:report_types) { %w[sast dast] }

    subject { described_class.with_report_types(report_types) }

    it 'returns vulnerabilities matching the given report_types' do
      is_expected.to contain_exactly(sast_vulnerability.vulnerability_read, dast_vulnerability.vulnerability_read)
    end
  end

  describe '.with_severities' do
    let!(:high_vulnerability) { create(:vulnerability, :with_finding, :high) }
    let!(:medium_vulnerability) { create(:vulnerability, :with_finding, :medium) }
    let(:low_vulnerability) { create(:vulnerability, :with_finding, :low) }
    let(:severities) { %w[medium low] }

    subject { described_class.with_severities(severities) }

    it 'returns vulnerabilities matching the given severities' do
      is_expected.to contain_exactly(medium_vulnerability.vulnerability_read, low_vulnerability.vulnerability_read)
    end
  end

  describe '.with_states' do
    let!(:detected_vulnerability) { create(:vulnerability, :with_finding, :detected) }
    let!(:dismissed_vulnerability) { create(:vulnerability, :with_finding, :dismissed) }
    let(:confirmed_vulnerability) { create(:vulnerability, :with_finding, :confirmed) }
    let(:states) { %w[detected confirmed] }

    subject { described_class.with_states(states) }

    it 'returns vulnerabilities matching the given states' do
      is_expected.to contain_exactly(detected_vulnerability.vulnerability_read, confirmed_vulnerability.vulnerability_read)
    end
  end

  describe '.with_scanner_external_ids' do
    let!(:vulnerability_1) { create(:vulnerability, :with_finding) }
    let!(:vulnerability_2) { create(:vulnerability, :with_finding) }
    let(:vulnerability_3) { create(:vulnerability, :with_finding) }
    let(:scanner_external_ids) { [vulnerability_1.finding_scanner_external_id, vulnerability_3.finding_scanner_external_id] }

    subject { described_class.with_scanner_external_ids(scanner_external_ids) }

    it 'returns vulnerabilities matching the given scanner external IDs' do
      is_expected.to contain_exactly(vulnerability_1.vulnerability_read, vulnerability_3.vulnerability_read)
    end
  end

  describe '.with_container_image' do
    let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: 'cluster_image_scanning') }
    let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, project: project, vulnerability: vulnerability) }

    let_it_be(:vulnerability_with_different_image) { create(:vulnerability, project: project, report_type: 'cluster_image_scanning') }
    let_it_be(:finding_with_different_image) do
      create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata,
        project: project, vulnerability: vulnerability_with_different_image, location_image: 'alpine:latest')
    end

    let_it_be(:image) { finding.location['image'] }

    subject(:cluster_vulnerabilities) { described_class.with_container_image(image) }

    it 'returns vulnerabilities with given image' do
      expect(cluster_vulnerabilities).to contain_exactly(vulnerability.vulnerability_read)
    end
  end

  describe '.with_resolution' do
    let_it_be(:vulnerability_with_resolution) { create(:vulnerability, :with_finding, resolved_on_default_branch: true) }
    let_it_be(:vulnerability_without_resolution) { create(:vulnerability, :with_finding, resolved_on_default_branch: false) }

    subject { described_class.with_resolution(with_resolution) }

    context 'when no argument is provided' do
      subject { described_class.with_resolution }

      it { is_expected.to match_array([vulnerability_with_resolution.vulnerability_read]) }
    end

    context 'when the argument is provided' do
      context 'when the given argument is `true`' do
        let(:with_resolution) { true }

        it { is_expected.to match_array([vulnerability_with_resolution.vulnerability_read]) }
      end

      context 'when the given argument is `false`' do
        let(:with_resolution) { false }

        it { is_expected.to match_array([vulnerability_without_resolution.vulnerability_read]) }
      end
    end
  end

  describe '.with_issues' do
    let_it_be(:vulnerability_with_issues) { create(:vulnerability, :with_finding, :with_issue_links) }
    let_it_be(:vulnerability_without_issues) { create(:vulnerability, :with_finding) }

    subject { described_class.with_issues(with_issues) }

    context 'when no argument is provided' do
      subject { described_class.with_issues }

      it { is_expected.to match_array([vulnerability_with_issues.vulnerability_read]) }
    end

    context 'when the argument is provided' do
      context 'when the given argument is `true`' do
        let(:with_issues) { true }

        it { is_expected.to match_array([vulnerability_with_issues.vulnerability_read]) }
      end

      context 'when the given argument is `false`' do
        let(:with_issues) { false }

        it { is_expected.to match_array([vulnerability_without_issues.vulnerability_read]) }
      end
    end
  end

  describe '.as_vulnerabilities' do
    let!(:vulnerability_1) { create(:vulnerability, :with_finding) }
    let!(:vulnerability_2) { create(:vulnerability, :with_finding) }
    let!(:vulnerability_3) { create(:vulnerability, :with_finding) }

    subject { described_class.as_vulnerabilities }

    it 'returns vulnerabilities as list' do
      is_expected.to contain_exactly(vulnerability_1, vulnerability_2, vulnerability_3)
    end
  end

  describe '.order_by' do
    let_it_be(:vulnerability_1) { create(:vulnerability, :with_finding, :low) }
    let_it_be(:vulnerability_2) { create(:vulnerability, :with_finding, :critical) }
    let_it_be(:vulnerability_3) { create(:vulnerability, :with_finding, :medium) }

    subject { described_class.order_by(method) }

    context 'when method is nil' do
      let(:method) { nil }

      it { is_expected.to match_array([vulnerability_2.vulnerability_read, vulnerability_3.vulnerability_read, vulnerability_1.vulnerability_read]) }
    end

    context 'when ordered by severity_desc' do
      let(:method) { :severity_desc }

      it { is_expected.to match_array([vulnerability_2.vulnerability_read, vulnerability_3.vulnerability_read, vulnerability_1.vulnerability_read]) }
    end

    context 'when ordered by severity_asc' do
      let(:method) { :severity_asc }

      it { is_expected.to match_array([vulnerability_1.vulnerability_read, vulnerability_3.vulnerability_read, vulnerability_2.vulnerability_read]) }
    end

    context 'when ordered by detected_desc' do
      let(:method) { :detected_desc }

      it { is_expected.to match_array([vulnerability_3.vulnerability_read, vulnerability_2.vulnerability_read, vulnerability_1.vulnerability_read]) }
    end

    context 'when ordered by detected_asc' do
      let(:method) { :detected_asc }

      it { is_expected.to match_array([vulnerability_1.vulnerability_read, vulnerability_2.vulnerability_read, vulnerability_3.vulnerability_read]) }
    end
  end

  describe '.order_severity_' do
    let_it_be(:low_vulnerability) { create(:vulnerability, :with_finding, :low) }
    let_it_be(:critical_vulnerability) { create(:vulnerability, :with_finding, :critical) }
    let_it_be(:medium_vulnerability) { create(:vulnerability, :with_finding, :medium) }

    describe 'ascending' do
      subject { described_class.order_severity_asc }

      it { is_expected.to match_array([low_vulnerability.vulnerability_read, medium_vulnerability.vulnerability_read, critical_vulnerability.vulnerability_read]) }
    end

    describe 'descending' do
      subject { described_class.order_severity_desc }

      it { is_expected.to match_array([critical_vulnerability.vulnerability_read, medium_vulnerability.vulnerability_read, low_vulnerability.vulnerability_read]) }
    end
  end

  describe '.order_detected_at_' do
    let_it_be(:old_vulnerability) { create(:vulnerability, :with_finding) }
    let_it_be(:new_vulnerability) { create(:vulnerability, :with_finding) }

    describe 'ascending' do
      subject { described_class.order_detected_at_asc }

      it 'returns vulnerabilities ordered by created_at' do
        is_expected.to match_array([old_vulnerability.vulnerability_read, new_vulnerability.vulnerability_read])
      end
    end

    describe 'descending' do
      subject { described_class.order_detected_at_desc }

      it 'returns vulnerabilities ordered by created_at' do
        is_expected.to match_array([new_vulnerability.vulnerability_read, old_vulnerability.vulnerability_read])
      end
    end
  end

  describe '.container_images' do
    let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: 'cluster_image_scanning') }
    let_it_be(:finding) { create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata, project: project, vulnerability: vulnerability) }

    let_it_be(:vulnerability_with_different_image) { create(:vulnerability, project: project, report_type: 'cluster_image_scanning') }
    let_it_be(:finding_with_different_image) do
      create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata,
        project: project, vulnerability: vulnerability_with_different_image, location_image: 'alpine:latest')
    end

    subject(:container_images) { described_class.all.container_images }

    it 'returns container images for vulnerabilities' do
      expect(container_images.map(&:location_image)).to match_array(['alpine:3.7', 'alpine:latest'])
    end
  end

  describe '.by_scanner' do
    let_it_be(:scanner) { create(:vulnerabilities_scanner, project: project) }
    let_it_be(:other_scanner) { create(:vulnerabilities_scanner, project: project) }
    let_it_be(:finding) { create(:vulnerabilities_finding, scanner: scanner) }
    let_it_be(:other_finding) { create(:vulnerabilities_finding, scanner: other_scanner) }
    let_it_be(:vulnerability) { create(:vulnerability, project: project, present_on_default_branch: true, findings: [finding]) }
    let_it_be(:vulnerability_for_another_scanner) { create(:vulnerability, project: project, present_on_default_branch: true, findings: [other_finding]) }

    subject(:vulnerability_reads) { described_class.by_scanner(scanner) }

    it 'returns records by given scanner' do
      expect(vulnerability_reads.pluck(:vulnerability_id)).to match_array([vulnerability.id])
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
