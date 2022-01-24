# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportScheduleWorker do
  let!(:project) { create(:project) }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let!(:import_state) { create(:import_state, :none, project: project) }

      let(:job_args) { [project.id] }

      let(:job_tracker_instance) { double(LimitedCapacity::JobTracker) }

      before do
        allow(Gitlab::Mirror).to receive(:available_capacity).and_return(5)
        allow(LimitedCapacity::JobTracker).to receive(:new).with('ProjectImportScheduleWorker').and_return(job_tracker_instance)
        allow(job_tracker_instance).to receive(:register)
        allow(job_tracker_instance).to receive(:remove)

        allow(Project).to receive(:find_by_id).with(project.id).and_return(project)
        allow(project).to receive(:add_import_job)
      end

      it 'does nothing if the database is read-only' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        expect(ProjectImportState).not_to receive(:project_id).with(project_id: project.id)

        subject
      end

      it 'schedules an import for a project' do
        expect(project).to receive(:add_import_job)
        expect(import_state).to be_none

        subject

        expect(import_state).to be_scheduled
      end

      it 'tracks the status of the worker' do
        subject

        expect(job_tracker_instance).to have_received(:register).with(any_args, 5).at_least(:once)
        expect(job_tracker_instance).to have_received(:remove).with(any_args).at_least(:once)
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
