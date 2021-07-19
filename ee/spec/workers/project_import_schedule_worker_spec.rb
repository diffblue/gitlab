# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportScheduleWorker do
  let!(:project) { create(:project) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let!(:import_state) { create(:import_state, :none, project: project) }

      let(:job_args) { [project.id] }

      before do
        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(project).to receive(:add_import_job)
      end

      it 'does nothing if the database is read-only' do
        allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
        expect(ProjectImportState).not_to receive(:project_id).with(project_id: project.id)

        subject
      end

      it 'schedules an import for a project' do
        expect(project).to receive(:add_import_job)
        expect(import_state).to be_none

        subject

        expect(import_state).to be_scheduled
      end
    end

    context 'project is not found' do
      it 'raises ImportStateNotFound' do
        expect { subject.perform(-1) }.to raise_error(described_class::ImportStateNotFound)
      end
    end

    context 'project does not have import state' do
      it 'raises ImportStateNotFound' do
        expect(project.import_state).to be_nil

        expect { subject.perform(project.id) }.to raise_error(described_class::ImportStateNotFound)
      end
    end
  end
end
