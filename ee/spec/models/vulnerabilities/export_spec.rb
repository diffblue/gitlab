# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Export, feature_category: :vulnerability_management do
  it { is_expected.to define_enum_for(:format) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:author).class_name('User').required }
  end

  describe 'validations' do
    subject(:export) { build(:vulnerability_export) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:format) }
    it { is_expected.not_to validate_presence_of(:file) }

    context 'when export is finished' do
      subject(:export) { build(:vulnerability_export, :finished) }

      it { is_expected.to validate_presence_of(:file) }
    end

    describe 'presence of both project and group' do
      let(:export) { build(:vulnerability_export, project: project, group: group) }
      let(:expected_error) { _('Project & Group can not be assigned at the same time') }

      subject { export.errors[:base] }

      before do
        export.validate
      end

      context 'when the project is present' do
        let(:project) { build(:project) }

        context 'when the group is present' do
          let(:group) { build(:group) }

          it { is_expected.to include(expected_error) }
        end

        context 'when the group is not present' do
          let(:group) { nil }

          it { is_expected.not_to include(expected_error) }
        end
      end

      context 'when the project is not present' do
        let(:project) { nil }

        context 'when the group is present' do
          let(:group) { build(:group) }

          it { is_expected.not_to include(expected_error) }
        end

        context 'when the group is not present' do
          let(:group) { nil }

          it { is_expected.not_to include(expected_error) }
        end
      end
    end
  end

  describe '#status' do
    subject(:vulnerability_export) { create(:vulnerability_export, :csv) }

    around do |example|
      freeze_time { example.run }
    end

    context 'when the export is new' do
      it { is_expected.to have_attributes(status: 'created') }
    end

    context 'when the export starts' do
      before do
        vulnerability_export.start!
      end

      it { is_expected.to have_attributes(status: 'running', started_at: Time.current) }
    end

    context 'when the export is running' do
      context 'and it finishes' do
        subject(:vulnerability_export) { create(:vulnerability_export, :csv, :with_file, :running) }

        before do
          vulnerability_export.finish!
        end

        it { is_expected.to have_attributes(status: 'finished', finished_at: Time.current) }
      end

      context 'and it fails' do
        subject(:vulnerability_export) { create(:vulnerability_export, :csv, :running) }

        before do
          vulnerability_export.failed!
        end

        it { is_expected.to have_attributes(status: 'failed', finished_at: Time.current) }
      end
    end
  end

  describe '#exportable' do
    subject { vulnerability_export.exportable }

    context 'when the export has project assigned' do
      let(:project) { build(:project) }
      let(:vulnerability_export) { build(:vulnerability_export, project: project) }

      it { is_expected.to eq(project) }
    end

    context 'when the export does not have project assigned' do
      context 'when the export has group assigned' do
        let(:group) { build(:group) }
        let(:vulnerability_export) { build(:vulnerability_export, :group, group: group) }

        it { is_expected.to eq(group) }
      end

      context 'when the export does not have group assigned' do
        let(:author) { build(:user) }
        let(:vulnerability_export) { build(:vulnerability_export, :user, author: author) }
        let(:mock_security_dashboard) { instance_double(InstanceSecurityDashboard) }

        before do
          allow(author).to receive(:security_dashboard).and_return(mock_security_dashboard)
        end

        it { is_expected.to eq(mock_security_dashboard) }
      end
    end
  end

  describe '#exportable=' do
    let(:vulnerability_export) { build(:vulnerability_export) }

    subject(:set_exportable) { vulnerability_export.exportable = exportable }

    context 'when the exportable is a Project' do
      let(:exportable) { build(:project) }

      it 'changes the exportable of the export to given project' do
        expect { set_exportable }.to change { vulnerability_export.exportable }.to(exportable)
      end
    end

    context 'when the exportable is a Group' do
      let(:exportable) { build(:group) }

      it 'changes the exportable of the export to given group' do
        expect { set_exportable }.to change { vulnerability_export.exportable }.to(exportable)
      end
    end

    context 'when the exportable is an InstanceSecurityDashboard' do
      let(:exportable) { InstanceSecurityDashboard.new(vulnerability_export.author) }

      before do
        allow(vulnerability_export.author).to receive(:security_dashboard).and_return(exportable)
      end

      it 'changes the exportable of the export to security dashboard of the author' do
        expect { set_exportable }.to change { vulnerability_export.exportable }.to(exportable)
      end
    end

    context 'when the exportable is a String' do
      let(:exportable) { 'Foo' }

      it 'raises an exception' do
        expect { set_exportable }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#completed?' do
    context 'when status is created' do
      subject { build(:vulnerability_export, :created) }

      it { is_expected.not_to be_completed }
    end

    context 'when status is running' do
      subject { build(:vulnerability_export, :running) }

      it { is_expected.not_to be_completed }
    end

    context 'when status is finished' do
      subject { build(:vulnerability_export, :finished) }

      it { is_expected.to be_completed }
    end

    context 'when status is failed' do
      subject { build(:vulnerability_export, :failed) }

      it { is_expected.to be_completed }
    end
  end
end
