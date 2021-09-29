# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TasksToBeDone::CreateWorker do
  subject(:worker) { described_class.new }

  describe '.perform' do
    let(:project) { create(:project) }
    let(:current_user) { create(:user) }
    let(:assignee_ids) { [1, 2] }

    it 'executes the task services for all available tasks to be done', :aggregate_failures do
      expect(TasksToBeDone::CreateCodeTaskService)
        .to receive(:new)
        .with(project: project, current_user: current_user, assignee_ids: assignee_ids)
        .and_call_original
      expect(TasksToBeDone::CreateCiTaskService)
        .to receive(:new)
        .with(project: project, current_user: current_user, assignee_ids: assignee_ids)
        .and_call_original
      expect(TasksToBeDone::CreateIssuesTaskService)
        .to receive(:new)
        .with(project: project, current_user: current_user, assignee_ids: assignee_ids)
        .and_call_original

      worker.perform(project.id, current_user.id, assignee_ids, Member::TASKS_TO_BE_DONE.keys)
    end
  end
end
