# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::DependencyListExport, feature_category: :dependency_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  describe 'associations' do
    subject(:export) { build(:dependency_list_export, project: project) }

    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:author).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:export_type) }
    it { is_expected.not_to validate_presence_of(:file) }

    context 'when export is finished' do
      subject(:export) { build(:dependency_list_export, :finished, project: project) }

      it { is_expected.to validate_presence_of(:file) }
    end

    describe 'only one exportable can be set' do
      let(:expected_error) { { error: 'Only one exportable is required' } }

      subject { export.errors.details[:base] }

      before do
        export.validate
      end

      context 'when project and group is set' do
        let(:export) { build(:dependency_list_export, project: project, group: group) }

        it { is_expected.to include(expected_error) }
      end

      context 'when project and pipeline is set' do
        let(:export) { build(:dependency_list_export, project: project, pipeline: pipeline) }

        it { is_expected.to include(expected_error) }
      end

      context 'when pipeline and group is set' do
        let(:export) { build(:dependency_list_export, pipeline: pipeline, group: group) }

        it { is_expected.to include(expected_error) }
      end

      context 'when project, group and pipeline is set' do
        let(:export) { build(:dependency_list_export, project: project, group: group, pipeline: pipeline) }

        it { is_expected.to include(expected_error) }
      end

      context 'when none is set' do
        let(:export) { build(:dependency_list_export, project: nil, group: nil, pipeline: nil) }

        it { is_expected.to include(expected_error) }
      end

      context 'when only project is set' do
        let(:export) { build(:dependency_list_export, project: project, group: nil) }

        it { is_expected.not_to include(expected_error) }
      end

      context 'when only group is set' do
        let(:export) { build(:dependency_list_export, project: nil, group: group, pipeline: nil) }

        it { is_expected.not_to include(expected_error) }
      end

      context 'when only pipeline is set' do
        let(:export) { build(:dependency_list_export, project: nil, group: nil, pipeline: pipeline) }

        it { is_expected.not_to include(expected_error) }
      end
    end
  end

  describe '#status' do
    subject(:dependency_list_export) { create(:dependency_list_export, project: project) }

    around do |example|
      freeze_time { example.run }
    end

    context 'when the export is new' do
      it { is_expected.to have_attributes(status: 0) }

      context 'and it fails' do
        before do
          dependency_list_export.failed!
        end

        it { is_expected.to have_attributes(status: -1) }
      end
    end

    context 'when the export starts' do
      before do
        dependency_list_export.start!
      end

      it { is_expected.to have_attributes(status: 1) }
    end

    context 'when the export is running' do
      context 'and it finishes' do
        subject(:dependency_list_export) { create(:dependency_list_export, :with_file, :running, project: project) }

        before do
          dependency_list_export.finish!
        end

        it { is_expected.to have_attributes(status: 2) }
      end

      context 'and it fails' do
        subject(:dependency_list_export) { create(:dependency_list_export, :running, project: project) }

        before do
          dependency_list_export.failed!
        end

        it { is_expected.to have_attributes(status: -1) }
      end
    end
  end

  describe '#retrieve_upload' do
    let(:dependency_list_export) { create(:dependency_list_export, :finished, project: project) }
    let(:relative_path) { dependency_list_export.file.url[1..] }

    subject(:retrieve_upload) { dependency_list_export.retrieve_upload(dependency_list_export, relative_path) }

    it { is_expected.to be_present }
  end

  describe '#exportable' do
    let(:export) do
      build(:dependency_list_export,
        project: project,
        group: group,
        pipeline: pipeline)
    end

    subject { export.exportable }

    context 'when the exportable is a project' do
      let(:group) { nil }
      let(:pipeline) { nil }

      it { is_expected.to eq(project) }
    end

    context 'when the exportable is a group' do
      let(:project) { nil }
      let(:pipeline) { nil }

      it { is_expected.to eq(group) }
    end

    context 'when the exportable is a pipeline' do
      let(:project) { nil }
      let(:group) { nil }

      it { is_expected.to eq(pipeline) }
    end
  end

  describe '#exportable=' do
    context 'when the given argument is a project' do
      let(:export) { build(:dependency_list_export, group: group, pipeline: pipeline) }

      it 'assigns the project and unassigns the group' do
        expect { export.exportable = project }.to change { export.project }.to(project)
                                              .and change { export.group }.to(nil)
                                              .and change { export.pipeline }.to(nil)
      end
    end

    context 'when the given argument is a group' do
      let(:export) { build(:dependency_list_export, project: project, pipeline: pipeline) }

      it 'assigns the group and unassigns the project' do
        expect { export.exportable = group }.to change { export.group }.to(group)
                                            .and change { export.project }.to(nil)
                                            .and change { export.pipeline }.to(nil)
      end
    end

    context 'when the given argument is a pipeline' do
      let(:export) { build(:dependency_list_export, group: group, project: project) }

      it 'assigns the pipeline and unassigns the group' do
        expect { export.exportable = pipeline }.to change { export.pipeline }.to(pipeline)
                                            .and change { export.project }.to(nil)
                                            .and change { export.group }.to(nil)
      end
    end

    context 'when the given argument is neither a project, group or pipeline' do
      let(:export) { build(:dependency_list_export) }

      it 'raises an error' do
        expect { export.exportable = nil }.to raise_error(RuntimeError)
      end
    end
  end
end
