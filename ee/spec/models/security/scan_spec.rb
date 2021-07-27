# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Scan do
  describe 'associations' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to have_one(:pipeline).through(:build).class_name('Ci::Pipeline') }
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

  describe '#project' do
    it { is_expected.to delegate_method(:project).to(:build) }
  end

  describe '#name' do
    it { is_expected.to delegate_method(:name).to(:build) }
  end

  describe '#has_errors?' do
    let(:scan) { build(:security_scan, info: info) }

    subject { scan.has_errors? }

    context 'when the info attribute is nil' do
      let(:info) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when the info attribute presents' do
      let(:info) { { errors: errors } }

      context 'when there is no error' do
        let(:errors) { [] }

        it { is_expected.to be_falsey }
      end

      context 'when there are errors' do
        let(:errors) { [{ type: 'Foo', message: 'Bar' }] }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.by_scan_types' do
    let!(:sast_scan) { create(:security_scan, scan_type: :sast) }
    let!(:dast_scan) { create(:security_scan, scan_type: :dast) }
    let(:expected_scans) { [sast_scan] }

    subject { described_class.by_scan_types(:sast) }

    it { is_expected.to match_array(expected_scans) }
  end

  describe '.latest_successful_by_build' do
    let!(:first_successful_scan) { create(:security_scan, build: create(:ci_build, :success, :retried)) }
    let!(:second_successful_scan) { create(:security_scan, build: create(:ci_build, :success)) }
    let!(:failed_scan) { create(:security_scan, build: create(:ci_build, :failed)) }

    subject { described_class.latest_successful_by_build }

    it { is_expected.to match_array([second_successful_scan]) }
  end

  describe '.has_dismissal_feedback' do
    let(:scan_1) { create(:security_scan) }
    let(:scan_2) { create(:security_scan) }
    let(:expected_scans) { [scan_1] }

    subject { described_class.has_dismissal_feedback }

    before do
      create(:vulnerability_feedback, :dismissal, project: scan_1.project, category: scan_1.scan_type)
      create(:vulnerability_feedback, :issue, project: scan_2.project, category: scan_2.scan_type)
    end

    it { is_expected.to match_array(expected_scans) }
  end

  it_behaves_like 'having unique enum values'

  it 'sets `project_id` and `pipeline_id` before save' do
    scan = create(:security_scan)
    scan.update_columns(project_id: nil, pipeline_id: nil)

    scan.save!

    expect(scan.project_id).to eq(scan.build.project_id)
    expect(scan.pipeline_id).to eq(scan.build.commit_id)
  end
end
