# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Importer, feature_category: :importers do
  let(:user) { create(:user) }
  let(:test_path) { "#{Dir.tmpdir}/importer_spec" }
  let(:shared) { project.import_export_shared }
  let(:import_file) { fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz') }
  let_it_be(:project) { create(:project) }

  subject(:importer) { described_class.new(project) }

  before do
    allow(Gitlab::ImportExport).to receive(:storage_path).and_return(test_path)
    allow_next_instance_of(Gitlab::ImportExport::FileImporter) do |instance|
      allow(instance).to receive(:remove_import_file)
    end
    stub_uploads_object_storage(FileUploader)

    FileUtils.mkdir_p(shared.export_path)
    ImportExportUpload.create!(project: project, import_file: import_file)
    allow(FileUtils).to receive(:rm_rf).and_call_original
  end

  after do
    FileUtils.rm_rf(test_path)
  end

  describe '#execute' do
    before do
      allow(project).to receive(:gitlab_custom_project_template_import?).and_return(true)
    end

    context 'when all EE restores are executed' do
      [
        Gitlab::ImportExport::Project::CustomTemplateRestorer
      ].each do |restorer|
        it "calls the #{restorer}" do
          fake_restorer = instance_double(restorer.to_s)

          expect(fake_restorer).to receive(:restore).and_return(true).once
          expect(restorer).to receive(:new).and_return(fake_restorer).once

          importer.execute
        end
      end

      context 'with template_project_id' do
        it 'initializes the CustomTemplateRestorer' do
          project.create_or_update_import_data(data: { template_project_id: project.id })

          expect(Gitlab::ImportExport::Project::CustomTemplateRestorer).to receive(:new).and_call_original

          importer.execute
        end
      end

      context 'without template_project_id' do
        it 'initializes the CustomTemplateRestorer' do
          allow(project).to receive(:gitlab_custom_project_template_import?).and_return(false)

          expect(Gitlab::ImportExport::Project::CustomTemplateRestorer).not_to receive(:new)

          importer.execute
        end
      end
    end
  end
end
