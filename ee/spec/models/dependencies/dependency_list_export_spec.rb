# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dependencies::DependencyListExport, feature_category: :dependency_management do
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    subject(:export) { build(:dependency_list_export, project: project) }

    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:author).class_name('User') }
  end

  describe 'validations' do
    subject(:export) { build(:dependency_list_export, project: project) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.not_to validate_presence_of(:file) }

    context 'when export is finished' do
      subject(:export) { build(:dependency_list_export, :finished, project: project) }

      it { is_expected.to validate_presence_of(:file) }
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
end
