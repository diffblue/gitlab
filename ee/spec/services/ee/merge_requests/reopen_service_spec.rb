# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ReopenService, feature_category: :code_review_workflow do
  describe '#execute' do
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:project) { merge_request.target_project }

    let(:service_object) { described_class.new(project: project, current_user: merge_request.author) }

    subject(:merge_request_reopen_service) { service_object.execute(merge_request) }

    context 'for audit events' do
      let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }
      let_it_be(:merge_request) { create(:merge_request, author: project_bot) }

      include_examples 'audit event logging' do
        let(:operation) { merge_request_reopen_service }
        let(:event_type) { 'merge_request_reopened_by_project_bot' }
        let(:fail_condition!) { expect(project_bot).to receive(:project_bot?).and_return(false) }
        let(:attributes) do
          {
            author_id: project_bot.id,
            entity_id: merge_request.target_project.id,
            entity_type: 'Project',
            details: {
              author_name: project_bot.name,
              target_id: merge_request.id,
              target_type: 'MergeRequest',
              target_details: {
                iid: merge_request.iid,
                id: merge_request.id,
                source_branch: merge_request.source_branch,
                target_branch: merge_request.target_branch
              }.to_s,
              author_class: project_bot.class.name,
              custom_message: "Reopened merge request #{merge_request.title}"
            }
          }
        end
      end
    end
  end
end
