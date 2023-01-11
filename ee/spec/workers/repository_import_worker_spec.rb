# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryImportWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  it 'updates the error on custom project template Import/Export' do
    create(:import_state, :scheduled, project: project)

    stub_licensed_features(custom_project_templates: true)
    error = %q{remote: Not Found fatal: repository 'https://user:pass@test.com/root/repoC.git/' not found }

    project.update!(import_type: 'gitlab_custom_project_template')
    project.import_state.update!(jid: '123')
    expect_next_instance_of(Projects::ImportService) do |service|
      expect(service).to receive(:execute).and_return({ status: :error, message: error })
    end

    subject.perform(project.id)

    expect(project.import_state.reload.last_error).to include('remote: Not Found fatal')
  end

  context 'when project is a mirror' do
    before do
      create(:import_state, :mirror, :scheduled, project: project)
    end

    it 'adds mirror in front of the mirror scheduler queue' do
      expect_next_instance_of(Projects::ImportService) do |service|
        expect(service).to receive(:execute).and_return({ status: :ok })
      end

      expect_any_instance_of(EE::ProjectImportState).to receive(:force_import_job!)

      subject.perform(project.id)
    end

    context 'when import failed' do
      it 'does not add import job' do
        expect_next_instance_of(Projects::ImportService) do |service|
          expect(service).to receive(:execute).and_return({ status: :error, message: 'error!' })
        end

        expect_any_instance_of(EE::ProjectImportState).not_to receive(:force_import_job!)

        subject.perform(project.id)
      end
    end
  end

  context 'when project not found (deleted)' do
    before do
      allow(Project).to receive(:find_by_id).with(project.id).and_return(nil)
    end

    it 'does not raise any exception' do
      expect { subject.perform(project.id) }.not_to raise_error
    end
  end

  describe 'sidekiq options' do
    it 'disables retry' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end

    it 'disables dead' do
      expect(described_class.sidekiq_options['dead']).to eq(false)
    end

    it 'sets default status expiration' do
      expect(described_class.sidekiq_options['status_expiration']).to eq(Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)
    end
  end
end
