# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewIssueWorker, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(project_bot)
  end

  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when project bot it logs audit events' do
      let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

      include_examples 'audit event logging' do
        let(:issue) { create(:issue, title: "My issue", project: project, author: project_bot) }
        let(:operation) { worker.perform(issue.id, project_bot.id) }
        let(:event_type) { 'issue_created_by_project_bot' }
        let(:fail_condition!) { allow_any_instance_of(User).to receive(:project_bot?).and_return(false) } # rubocop:disable RSpec/AnyInstanceOf
        let(:attributes) do
          {
            author_id: project_bot.id,
            entity_id: issue.project.id,
            entity_type: 'Project',
            details: {
              author_name: project_bot.name,
              target_id: issue.id,
              target_type: 'Issue',
              target_details: {
                iid: issue.iid,
                id: issue.id
              }.to_s,
              author_class: project_bot.class.name,
              custom_message: "Created issue #{issue.title}"
            }
          }
        end
      end
    end
  end
end
