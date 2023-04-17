# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Scan, feature_category: :vulnerability_management do
  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:security_scan) }
    let(:parent) { model.build }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to have_many(:findings) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:build_id) }
    it { is_expected.to validate_presence_of(:scan_type) }

    describe 'info' do
      let(:scan) { build(:security_scan, info: info) }

      subject { scan.errors.details[:info] }

      before do
        scan.validate
      end

      context 'when the value for info field is valid' do
        let(:info) { { errors: [{ type: 'Foo', message: 'Message' }] } }

        it { is_expected.to be_empty }
      end

      context 'when the value for info field is invalid' do
        let(:info) { { errors: [{ type: 'Foo' }] } }

        it { is_expected.not_to be_empty }
      end
    end
  end

  describe '#name' do
    it { is_expected.to delegate_method(:name).to(:build) }
  end

  describe '#findings_can_be_purged?' do
    let(:scan) { create(:security_scan, created_at: created_at, status: status) }

    subject { scan.findings_can_be_purged? }

    context 'when the record is created in less than 3 months ago' do
      let(:created_at) { 2.months.ago }

      context 'when the record is not purged' do
        let(:status) { :succeeded }

        it { is_expected.to be_falsey }
      end

      context 'when the record is purged' do
        let(:status) { :purged }

        it { is_expected.to be_falsey }
      end
    end

    context 'when the record is created in more than 3 months ago' do
      let(:created_at) { 4.months.ago }

      context 'when the record is not purged' do
        let(:status) { :succeeded }

        it { is_expected.to be_falsey }
      end

      context 'when the record is purged' do
        let(:status) { :purged }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#has_warnings?' do
    let(:scan) { build(:security_scan, info: info) }

    subject { scan.has_warnings? }

    context 'when the info attribute is nil' do
      let(:info) { nil }

      it 'is not valid' do
        expect(scan.valid?).to eq(false)
      end
    end

    context 'when the info attribute is present' do
      let(:info) { { warnings: warnings } }

      context 'when there is no warnings' do
        let(:warnings) { [] }

        it { is_expected.to eq(false) }
      end

      context 'when there are warnings' do
        let(:warnings) { [{ type: 'Foo', message: 'Bar' }] }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#processing_warnings' do
    let(:scan) { build(:security_scan, info: info) }
    let(:info) { { warnings: validator_warnings } }

    subject(:warnings) { scan.processing_warnings }

    context 'when there are warnings' do
      let(:validator_warnings) { [{ type: 'Foo', message: 'Bar' }] }

      it 'returns all warnings' do
        expect(warnings).to match_array([{ "message" => "Bar", "type" => "Foo" }])
      end
    end

    context 'when there are no warnings' do
      let(:validator_warnings) { [] }

      it 'returns []' do
        expect(warnings).to match_array(validator_warnings)
      end
    end
  end

  describe '#processing_warnings=' do
    let(:scan) { create(:security_scan) }

    subject(:set_warnings) { scan.processing_warnings = [:foo] }

    it 'sets the warnings' do
      expect { set_warnings }.to change { scan.info['warnings'] }.from(nil).to([:foo])
    end
  end

  describe '#has_warnings?' do
    let(:scan) { build(:security_scan, info: info) }
    let(:info) { { warnings: validator_warnings } }

    subject(:has_warnings?) { scan.has_warnings? }

    context 'when there are warnings' do
      let(:validator_warnings) { [{ type: 'Foo', message: 'Bar' }] }

      it 'returns true' do
        expect(has_warnings?).to eq(true)
      end
    end

    context 'when there are no warnings' do
      let(:validator_warnings) { [] }

      it 'returns false' do
        expect(has_warnings?).to eq(false)
      end
    end
  end

  describe '#has_errors?' do
    let(:scan) { build(:security_scan, info: info) }

    subject { scan.has_errors? }

    context 'when the info attribute is nil' do
      let(:info) { nil }

      it 'is not valid' do
        expect(scan.valid?).to eq(false)
      end
    end

    context 'when the info attribute presents' do
      let(:info) { { errors: errors } }

      context 'when there is no error' do
        let(:errors) { [] }

        it { is_expected.to eq(false) }
      end

      context 'when there are errors' do
        let(:errors) { [{ type: 'Foo', message: 'Bar' }] }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '.by_scan_types' do
    let_it_be(:sast_scan) { create(:security_scan, scan_type: :sast) }
    let_it_be(:dast_scan) { create(:security_scan, scan_type: :dast) }

    let(:expected_scans) { [sast_scan] }

    subject { described_class.by_scan_types(:sast) }

    it { is_expected.to match_array(expected_scans) }

    context 'when an invalid enum value is given' do
      subject { described_class.by_scan_types([:sast, :generic]) }

      it { is_expected.to match_array(expected_scans) }
    end
  end

  describe '.by_project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }

    let_it_be(:sast_scan) { create(:security_scan, scan_type: :sast, project: project) }
    let_it_be(:dast_scan) { create(:security_scan, scan_type: :dast, project: other_project) }

    let(:expected_scans) { [sast_scan] }

    subject { described_class.by_project(project) }

    it { is_expected.to match_array(expected_scans) }
  end

  describe '.distinct_scan_types' do
    let_it_be(:sast_scan) { create(:security_scan, scan_type: :sast) }
    let_it_be(:sast_scan2) { create(:security_scan, scan_type: :sast) }
    let_it_be(:dast_scan) { create(:security_scan, scan_type: :dast) }

    let(:expected_scans) { %w(sast dast) }

    subject { described_class.distinct_scan_types }

    it { is_expected.to match_array(expected_scans) }
  end

  describe '.latest_successful' do
    let!(:first_successful_scan) { create(:security_scan, latest: false, status: :succeeded) }
    let!(:second_successful_scan) { create(:security_scan, latest: true, status: :succeeded) }
    let!(:failed_scan) { create(:security_scan, latest: true, status: :job_failed) }

    subject { described_class.latest_successful }

    it { is_expected.to match_array([second_successful_scan]) }
  end

  describe '.by_build_ids' do
    let!(:sast_scan) { create(:security_scan, scan_type: :sast) }
    let!(:dast_scan) { create(:security_scan, scan_type: :dast, build: sast_scan.build) }
    let(:expected_scans) { [sast_scan, dast_scan] }

    subject { described_class.by_build_ids(expected_scans.map(&:build_id)) }

    it { with_cross_joins_prevented { is_expected.to match_array(expected_scans) } }
  end

  describe '.has_dismissal_feedback' do
    let(:project_1) { create(:project) }
    let(:project_2) { create(:project) }
    let(:scan_1) { create(:security_scan, project: project_1) }
    let(:scan_2) { create(:security_scan, project: project_2) }
    let(:expected_scans) { [scan_1] }

    subject { described_class.has_dismissal_feedback }

    before do
      create(:vulnerability_feedback, :dismissal, project: project_1, category: scan_1.scan_type)
      create(:vulnerability_feedback, :issue, project: project_2, category: scan_2.scan_type)
    end

    it { is_expected.to match_array(expected_scans) }
  end

  describe '.without_errors' do
    let!(:scan_1) { create(:security_scan, :with_error) }
    let!(:scan_2) { create(:security_scan) }

    subject { described_class.without_errors }

    it { is_expected.to contain_exactly(scan_2) }
  end

  describe '.latest' do
    let!(:latest_scan) { create(:security_scan, latest: true) }
    let!(:retried_scan) { create(:security_scan, latest: false) }

    subject { described_class.latest }

    it { is_expected.to match_array([latest_scan]) }
  end

  describe '.stale' do
    let!(:stale_succeeded_scan) { create(:security_scan, status: :succeeded, created_at: 91.days.ago) }
    let!(:stale_failed_scan) { create(:security_scan, status: :preparation_failed, created_at: 91.days.ago) }
    let!(:stale_created_scan) { create(:security_scan, status: :created, created_at: 91.days.ago) }
    let!(:stale_job_failed_scan) { create(:security_scan, status: :job_failed, created_at: 91.days.ago) }
    let!(:stale_report_errored_scan) { create(:security_scan, status: :report_error, created_at: 91.days.ago) }
    let!(:stale_preparing_scan) { create(:security_scan, status: :preparing, created_at: 91.days.ago) }

    let(:expected_scans) do
      [stale_succeeded_scan, stale_failed_scan, stale_created_scan,
       stale_job_failed_scan, stale_report_errored_scan, stale_preparing_scan]
    end

    subject { described_class.stale }

    before do
      create(:security_scan, status: :succeeded)
      create(:security_scan, status: :preparation_failed)
      create(:security_scan, status: :purged, created_at: 91.days.ago)
    end

    it { is_expected.to match_array(expected_scans) }
  end

  describe '.ordered_by_created_at_and_id' do
    let(:created_at) { Time.zone.now }
    let!(:scan_1) { create(:security_scan, created_at: created_at) }
    let!(:scan_2) { create(:security_scan, created_at: created_at) }
    let!(:scan_3) { create(:security_scan, created_at: created_at - 1.minute) }

    subject { described_class.ordered_by_created_at_and_id }

    it { is_expected.to eq([scan_3, scan_1, scan_2]) }
  end

  describe '.with_warnings' do
    let!(:scan_1) { create(:security_scan) }
    let!(:scan_2) { create(:security_scan, :with_warning) }

    subject { described_class.with_warnings }

    it { is_expected.to contain_exactly(scan_2) }
  end

  describe '.with_errors' do
    let!(:scan_1) { create(:security_scan, :with_error) }
    let!(:scan_2) { create(:security_scan) }

    subject { described_class.with_errors }

    it { is_expected.to contain_exactly(scan_1) }
  end

  describe '#report_findings' do
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:scan) { create(:security_scan, build: artifact.job) }
    let(:artifact_finding_uuids) { artifact.security_report.findings.map(&:uuid) }

    subject { scan.report_findings.map(&:uuid) }

    it { is_expected.to match_array(artifact_finding_uuids) }
  end

  describe '#report_primary_identifiers' do
    it 'returns the matching primary_identifiers' do
      artifact = create(:ee_ci_job_artifact, :sast_semgrep_for_gosec)
      scan = create(:security_scan, scan_type: 'sast', build: artifact.job)

      expect(scan.report_primary_identifiers).to match_array(
        artifact.security_report.primary_identifiers
      )
    end
  end

  describe '#processing_errors' do
    let(:scan) { build(:security_scan, :with_error) }

    subject { scan.processing_errors }

    it { is_expected.to eq([{ 'type' => 'ParsingError', 'message' => 'Unknown error happened' }]) }
  end

  describe '#processing_errors=' do
    let(:scan) { create(:security_scan) }

    subject(:set_processing_errors) { scan.processing_errors = [:foo] }

    it 'sets the processing errors' do
      expect { set_processing_errors }.to change { scan.info['errors'] }.from(nil).to([:foo])
    end
  end

  describe '#add_processing_error!' do
    let(:error) { { type: 'foo', message: 'bar' } }

    subject(:add_processing_error) { scan.add_processing_error!(error) }

    context 'when the scan does not have any errors' do
      let(:scan) { create(:security_scan) }

      it 'persists the error' do
        expect { add_processing_error }.to change { scan.reload.info['errors'] }.from(nil).to([{ 'type' => 'foo', 'message' => 'bar' }])
      end
    end

    context 'when the scan already has some errors' do
      let(:scan) { create(:security_scan, :with_error) }

      it 'persists the new error with the existing ones' do
        expect { add_processing_error }.to change { scan.reload.info['errors'] }.from([{ 'type' => 'ParsingError', 'message' => 'Unknown error happened' }])
                                                                                .to([{ 'type' => 'ParsingError', 'message' => 'Unknown error happened' }, { 'type' => 'foo', 'message' => 'bar' }])
      end
    end
  end

  describe '#remediations_proxy' do
    let(:mock_file) { instance_double(JobArtifactUploader) }
    let(:scan) { create(:security_scan, :with_findings) }

    subject { scan.remediations_proxy }

    context 'when the artifact exists' do
      before do
        allow_next_found_instance_of(Ci::JobArtifact) do |artifact|
          allow(artifact).to receive(:file).and_return(mock_file)
        end
      end

      it { is_expected.to be_an_instance_of(Security::RemediationsProxy).and have_attributes(file: mock_file) }
    end

    context 'when the artifact is removed' do
      before do
        scan.build.job_artifacts.delete_all
      end

      it { is_expected.to be_an_instance_of(Security::RemediationsProxy).and have_attributes(file: nil) }
    end
  end

  it_behaves_like 'having unique enum values'

  it 'sets `project_id` and `pipeline_id` before save' do
    scan = create(:security_scan)
    scan.update_columns(project_id: nil, pipeline_id: nil)

    scan.save!

    expect(scan.project_id).to eq(scan.build.project_id)
    expect(scan.pipeline_id).to eq(scan.build.commit_id)
  end

  describe "#scanners" do
    let_it_be(:scan) { create(:security_scan, scan_type: :dependency_scanning) }
    let_it_be(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning_multiple_scanners, job: scan.build, project: scan.project) }
    let_it_be(:retirejs_scanner) { create(:vulnerabilities_scanner, project: scan.project, external_id: 'retire.js') }
    let_it_be(:gemnasium_scanner) { create(:vulnerabilities_scanner, project: scan.project, external_id: 'gemnasium') }
    let_it_be(:other_scanner) { create(:vulnerabilities_scanner, project: scan.project, external_id: 'other') }

    it 'returns the matching vulnerability scanner' do
      expect(scan.scanners).to contain_exactly(retirejs_scanner, gemnasium_scanner)
    end
  end
end
