# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::CloseService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(project_bot)
  end

  describe '#execute' do
    let(:service) { described_class.new(container: project, current_user: project_bot) }

    context 'when project bot it logs audit events' do
      let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

      include_examples 'audit event logging' do
        let(:issue) { create(:issue, title: "My issue", project: project, author: project_bot) }
        let(:operation) { service.execute(issue) }
        let(:event_type) { 'issue_closed_by_project_bot' }
        let(:fail_condition!) { expect(project_bot).to receive(:project_bot?).and_return(false) }
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
              custom_message: "Closed issue #{issue.title}"
            }
          }
        end
      end
    end
  end
end
