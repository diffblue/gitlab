# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TasksToBeDone::BaseService do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee_one) { create(:user) }
  let_it_be(:assignee_two) { create(:user) }
  let_it_be(:assignee_ids) { [assignee_one.id] }

  before do
    project.add_maintainer(current_user)
    project.add_developer(assignee_one)
    project.add_developer(assignee_two)
  end

  subject(:service) do
    TasksToBeDone::CreateCiTaskService.new(
      project: project,
      current_user: current_user,
      assignee_ids: assignee_ids
    )
  end

  context 'no existing task issue', :aggregate_failures do
    it 'creates an issue' do
      params = {
        assignee_ids: assignee_ids,
        title: 'Set up CI/CD',
        description: anything
      }

      expect(Issues::BuildService)
        .to receive(:new)
        .with(project: project, current_user: current_user, params: params)
        .and_call_original

      expect { service.execute }.to change(Issue, :count).by(1)

      issue = project.issues.last
      expect(issue.author).to eq(current_user)
      expect(issue.title).to eq('Set up CI/CD')
      expect(issue.assignees).to eq([assignee_one])
    end
  end

  context 'an issue with the same title already exists', :aggregate_failures do
    let_it_be(:assignee_ids) { [assignee_two.id] }

    it 'assigns the user to the existing issue' do
      issue = create(:issue, project: project, author: current_user, title: 'Set up CI/CD', assignees: [assignee_one])
      params = { add_assignee_ids: assignee_ids }

      expect(Issues::UpdateService)
        .to receive(:new)
        .with(project: project, current_user: current_user, params: params)
        .and_call_original

      expect { service.execute }.not_to change(Issue, :count)

      expect(issue.reload.assignees).to match_array([assignee_one, assignee_two])
    end
  end
end
