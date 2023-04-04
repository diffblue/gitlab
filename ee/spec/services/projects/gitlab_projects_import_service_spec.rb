# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GitlabProjectsImportService do
  let_it_be(:namespace) { create(:namespace) }

  let(:path) { 'test-path' }
  let(:custom_template) { create(:project) }
  let(:overwrite) { false }
  let(:import_params) { { namespace_id: namespace.id, path: path, custom_template: custom_template, overwrite: overwrite } }

  subject { described_class.new(namespace.owner, import_params) }

  after do
    TestEnv.clean_test_path
  end

  describe '#execute' do
    context 'creates template export job' do
      it 'if project saved and custom template exists' do
        expect(custom_template).to receive(:add_template_export_job)

        project = subject.execute

        expect(project.saved?).to be true
      end

      it 'sets custom template import strategy after export' do
        expect(custom_template)
          .to receive(:add_template_export_job).with(
            current_user: namespace.owner,
            after_export_strategy: instance_of(EE::Gitlab::ImportExport::AfterExportStrategies::CustomTemplateExportImportStrategy)
          )

        subject.execute
      end
    end

    context 'does not create export job' do
      it 'if project not saved' do
        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:saved?).and_return(false)
        end

        expect(custom_template).not_to receive(:add_template_export_job)

        project = subject.execute

        expect(project.saved?).to be false
      end
    end

    it_behaves_like 'gitlab projects import validations'
  end
end
