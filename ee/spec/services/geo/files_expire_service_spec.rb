# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FilesExpireService, :geo, feature_category: :geo_replication do
  let(:project) { create(:project, :legacy_storage) }
  let!(:old_full_path) { project.full_path }

  subject { described_class.new(project, old_full_path) }

  describe '#execute' do
    let(:file_uploader) { build(:file_uploader, project: project) }
    let!(:upload) { Upload.find_by(path: file_uploader.upload_path) }
    let!(:upload_registry) { create(:geo_upload_registry, :synced, file_id: upload.id) }

    before do
      project.update!(path: "#{project.path}_renamed")
    end

    context 'when in Geo secondary node' do
      before do
        allow(Gitlab::Geo).to receive(:secondary?) { true }
      end

      it 'remove file from disk' do
        file_path = File.join(subject.base_dir, upload.path)
        expect(File.exist?(file_path)).to be_truthy

        Sidekiq::Testing.inline! { subject.execute }

        expect(File.exist?(file_path)).to be_falsey
      end

      it 'removes upload_registry associates with upload' do
        expect(upload_registry.synced?).to be_truthy

        subject.execute

        expect { upload_registry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when not in Geo secondary node' do
      it 'no-op execute action' do
        expect(subject).not_to receive(:schedule_file_removal)

        subject.execute
      end
    end
  end
end
