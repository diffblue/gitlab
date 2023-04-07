# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Finding, feature_category: :vulnerability_management do
  let_it_be(:scan_1) { create(:security_scan, :latest_successful, scan_type: :sast) }
  let_it_be(:scan_2) { create(:security_scan, :latest_successful, scan_type: :dast) }
  let_it_be(:finding_1, refind: true) { create(:security_finding, scan: scan_1) }
  let_it_be(:finding_2, refind: true) { create(:security_finding, scan: scan_2) }

  describe 'associations' do
    it { is_expected.to belong_to(:scan).required }
    it { is_expected.to belong_to(:scanner).required }
    it { is_expected.to belong_to(:vulnerability_finding).class_name('Vulnerabilities::Finding') }
    it { is_expected.to have_one(:build).through(:scan) }
    it { is_expected.to have_one(:vulnerability).through(:vulnerability_finding) }
    it { is_expected.to have_many(:state_transitions).through(:vulnerability) }
    it { is_expected.to have_many(:issue_links).through(:vulnerability) }
    it { is_expected.to have_many(:merge_request_links).through(:vulnerability) }

    it {
      is_expected.to have_many(:feedbacks)
                  .with_primary_key('uuid')
                  .class_name('Vulnerabilities::Feedback')
                  .with_foreign_key('finding_uuid')
    }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:uuid) }

    describe 'finding_data attribute' do
      let(:finding) { build(:security_finding, finding_data: finding_data) }

      before do
        finding.validate
      end

      context 'when the finding_data has invalid fields' do
        let(:finding_data) { { remediation_byte_offsets: [{ start_byte: :foo, end_byte: 20 }] } }

        it 'adds errors' do
          expect(finding.errors.details.keys).to include(:finding_data)
        end
      end

      context 'when the finding_data has valid fields' do
        let(:finding_data) { { remediation_byte_offsets: [{ start_byte: 0, end_byte: 20 }] } }

        it 'does not add errors' do
          expect(finding.errors.details.keys).not_to include(:finding_data)
        end
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:scan_type).to(:scan).allow_nil }
  end

  describe '.by_uuid' do
    subject { described_class.by_uuid(finding_1.uuid) }

    it { is_expected.to match_array([finding_1]) }
  end

  describe '.by_build_ids' do
    subject { described_class.by_build_ids(finding_1.scan.build_id) }

    it { with_cross_joins_prevented { is_expected.to match_array([finding_1]) } }
  end

  describe '.by_severity_levels' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.by_severity_levels(:critical) }

    before do
      finding_1.update! severity: :high
      finding_2.update! severity: :critical
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_confidence_levels' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.by_confidence_levels(:high) }

    before do
      finding_1.update! confidence: :low
      finding_2.update! confidence: :high
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_report_types' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.by_report_types(:sast) }

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_project_fingerprints' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.by_project_fingerprints(finding_1.project_fingerprint) }

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_scanners' do
    subject { described_class.by_scanners(finding_1.scanner) }

    it { is_expected.to match_array([finding_1]) }
  end

  describe '.by_state' do
    context 'when the state is `detected`' do
      subject(:findings) { described_class.by_state(:detected) }

      before do
        create(:vulnerabilities_finding, :detected, uuid: finding_2.uuid)
      end

      it 'returns findings that are associated with "detected vulnerabilities" along with the recently detected ones' do
        expect(findings).to match_array([finding_1, finding_2])
      end
    end

    context 'when the state is `dismissed`' do
      subject { described_class.by_state(:dismissed, check_feedback: check_feedback?) }

      before do
        create(:vulnerability_feedback,
           :dismissal,
           project: scan_2.project,
           category: scan_2.scan_type,
           finding_uuid: finding_2.uuid)

        create(:vulnerabilities_finding, :dismissed, uuid: finding_1.uuid)
      end

      context 'when the `check_feedback` argument is false' do
        let(:check_feedback?) { false }

        it { is_expected.to match_array([finding_1]) }
      end

      context 'when the `check_feedback` argument is true' do
        let(:check_feedback?) { true }

        it { is_expected.to match_array([finding_1, finding_2]) }
      end
    end

    context 'when the state is `confirmed`' do
      subject { described_class.by_state(:confirmed) }

      before do
        create(:vulnerabilities_finding, :confirmed, uuid: finding_1.uuid)
      end

      it { is_expected.to match_array([finding_1]) }
    end

    context 'when the state is `resolved`' do
      subject { described_class.by_state(:resolved) }

      before do
        create(:vulnerabilities_finding, :resolved, uuid: finding_1.uuid)
      end

      it { is_expected.to match_array([finding_1]) }
    end
  end

  describe '.undismissed_by_vulnerability' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.undismissed_by_vulnerability }

    before do
      create(:vulnerabilities_finding,
             :dismissed,
             uuid: finding_1.uuid)
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.undismissed' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.undismissed }

    before do
      finding_2.update! scan: scan_1

      create(:vulnerability_feedback,
             :dismissal,
             project: scan_1.project,
             category: scan_1.scan_type,
             finding_uuid: finding_1.uuid)

      create(:vulnerability_feedback,
             :dismissal,
             project: scan_2.project,
             category: scan_2.scan_type,
             finding_uuid: finding_2.uuid)
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.ordered' do
    let_it_be(:finding_3) { create(:security_finding, severity: :critical) }
    let_it_be(:finding_4) { create(:security_finding, severity: :critical) }

    let(:expected_findings) { [finding_3, finding_4, finding_1, finding_2] }

    subject { described_class.ordered }

    before do
      finding_1.update!(severity: :high)
      finding_2.update!(severity: :low)
    end

    it { is_expected.to eq(expected_findings) }
  end

  describe '.deduplicated' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.deduplicated }

    before do
      finding_1.update! deduplicated: true
      finding_2.update! deduplicated: false
    end

    it { is_expected.to eq(expected_findings) }
  end

  describe '.count_by_scan_type' do
    subject { described_class.count_by_scan_type }

    let_it_be(:finding_3) { create(:security_finding, scan: scan_1) }

    it {
      is_expected.to eq({
        Security::Scan.scan_types['dast'] => 1,
        Security::Scan.scan_types['sast'] => 2
      })
    }
  end

  describe '.latest_by_uuid' do
    subject { described_class.latest_by_uuid(finding_1.uuid) }

    let_it_be(:newer_scan) { create(:security_scan, :latest_successful, scan_type: :sast) }
    let_it_be(:newer_finding) { create(:security_finding, uuid: finding_1.uuid, scan: newer_scan) }

    it { is_expected.to eq(newer_finding) }
  end

  describe '.partition_full?' do
    using RSpec::Parameterized::TableSyntax

    where(:partition_size, :considered_full?) do
      101.gigabytes     | true
      100.gigabytes     | true
      100.gigabytes - 1 | false
    end

    with_them do
      let(:mock_partition) do
        instance_double(Gitlab::Database::Partitioning::SingleNumericListPartition, data_size: partition_size)
      end

      subject { described_class.partition_full?(mock_partition) }

      it { is_expected.to eq(considered_full?) }
    end
  end

  describe '.detach_partition?' do
    subject { described_class.detach_partition?(partition_number) }

    context 'when there is no finding for the given partition number' do
      let(:partition_number) { 0 }

      it { is_expected.to be_falsey }
    end

    context 'when the partition is not empty' do
      let(:partition_number) { finding_2.partition_number }

      before do
        allow_next_found_instance_of(Security::Scan) do |scan|
          allow(scan).to receive(:findings_can_be_purged?).and_return(findings_can_be_purged?)
        end
      end

      context 'when the scan of last finding in partition returns false to findings_can_be_purged? message' do
        let(:findings_can_be_purged?) { false }

        it { is_expected.to be_falsey }
      end

      context 'when the scan of last finding in partition returns true to findings_can_be_purged? message' do
        let(:findings_can_be_purged?) { true }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.active_partition_number' do
    subject { described_class.active_partition_number }

    context 'when the `security_findings` is partitioned' do
      let(:expected_partition_number) { 9999 }

      before do
        allow_next_instance_of(Gitlab::Database::Partitioning::SingleNumericListPartition) do |partition|
          allow(partition).to receive(:value).and_return(expected_partition_number)
        end
      end

      it { is_expected.to match(expected_partition_number) }
    end

    context 'when the `security_findings` is not partitioned' do
      before do
        described_class.partitioning_strategy.current_partitions.each do |partition|
          ApplicationRecord.connection.execute(partition.to_detach_sql)
        end
      end

      it { is_expected.to match(1) }
    end
  end

  describe '.fetch_uuids' do
    it 'returns the uuids of findings' do
      findings = create_list(:security_finding, 2)

      expect(described_class.fetch_uuids).to include(findings.first.uuid, findings.second.uuid)
    end
  end

  describe '#state' do
    subject { finding_1.state }

    context 'when there is no associated vulnerability' do
      context 'when there is no associated dismissal feedback' do
        it { is_expected.to eq('detected') }
      end

      context 'when there is an associated dismissal feedback' do
        before do
          create(:vulnerability_feedback, :dismissal, finding_uuid: finding_1.uuid)
        end

        it { is_expected.to eq('dismissed') }
      end
    end

    context 'when there is an associated vulnerability' do
      where(:state) { %i[detected confirmed dismissed resolved] }

      before do
        create(:vulnerabilities_finding, state, uuid: finding_1.uuid)
      end

      with_them do
        it { is_expected.to eq(state.to_s) }
      end
    end
  end

  describe 'feedback accessors' do
    shared_examples_for 'has feedback method for' do |type|
      context 'when there is no associated dismissal feedback' do
        it { is_expected.to be_nil }
      end

      context 'when there is an associated dismissal feedback' do
        let!(:feedback) { create(:vulnerability_feedback, type, finding_uuid: finding_1.uuid) }

        it { is_expected.to eq(feedback) }
      end
    end

    describe '#dismissal_feedback' do
      it_behaves_like 'has feedback method for', :dismissal do
        subject { finding_1.dismissal_feedback }
      end
    end

    describe '#issue_feedback' do
      it_behaves_like 'has feedback method for', :issue do
        subject { finding_1.issue_feedback }
      end
    end

    describe '#merge_request_feedback' do
      it_behaves_like 'has feedback method for', :merge_request do
        subject { finding_1.merge_request_feedback }
      end
    end
  end

  describe 'attributes delegated to `finding_data`' do
    using RSpec::Parameterized::TableSyntax

    where(:attribute, :expected_value) do
      :name                     | 'Test finding'
      :description              | 'Test description'
      :solution                 | 'Test solution'
      :location                 | 'Test location'
      :identifiers              | ['Test identifier']
      :links                    | ['Test link']
      :false_positive?          | false
      :assets                   | ['Test asset']
      :evidence                 | {}
      :details                  | []
      :remediation_byte_offsets | { start_byte: 0, end_byte: 1 }
      :raw_source_code_extract  | 'AES/ECB/NoPadding'
    end

    with_them do
      let(:finding) { build(:security_finding) }

      subject { finding.send(attribute) }

      before do
        finding.finding_data[attribute] = expected_value
      end

      it { is_expected.to eq(expected_value) }
    end
  end

  describe 'finding_details delegated to `finding_data` details' do
    let(:finding) { build(:security_finding) }

    subject { finding.finding_details }

    before do
      finding.finding_data['details'] = [{ name: 'Test Detail' }]
    end

    it { is_expected.to eq([{ name: 'Test Detail' }]) }
  end

  describe '#remediations', :aggregate_failures do
    let(:finding) { create(:security_finding, finding_data: finding_data) }
    let(:mock_remediations) { [Object.new] }
    let(:mock_proxy) { instance_double(Security::RemediationsProxy, by_byte_offsets: mock_remediations) }

    subject(:remediations) { finding.remediations }

    before do
      allow(finding.scan).to receive(:remediations_proxy).and_return(mock_proxy)
    end

    context 'when the remediation byte offsets do not exist' do
      let(:finding_data) { {} }

      it 'does not call the proxy and returns an empty array' do
        expect(remediations).to be_empty
        expect(mock_proxy).not_to have_received(:by_byte_offsets)
      end
    end

    context 'when the remediation byte offsets exist' do
      let(:finding_data) { { remediation_byte_offsets: [{ start_byte: 0, end_byte: 10 }] } }

      it 'delegates the call to the proxy' do
        expect(remediations).to eq(mock_remediations)
        expect(mock_proxy).to have_received(:by_byte_offsets)
      end
    end
  end
end
