# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CloseService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:current_user) { merge_request.author }
  let(:service) { described_class.new(project: project, current_user: current_user) }

  describe '#execute' do
    it 'executes the close service' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:execute)
          .with(merge_request)
      end

      service.execute(merge_request)
    end

    context 'when a temporary unapproval is needed for the MR' do
      it 'removes the unmergeable flag after the service is run' do
        merge_request.approval_state.temporarily_unapprove!

        service.execute(merge_request)

        merge_request.reload

        expect(merge_request.approval_state.temporarily_unapproved?).to be_falsey
      end

      context 'when the service fails' do
        before do
          allow_next_instance_of(described_class) do |close_service|
            allow(close_service).to receive(:execute).and_return(ServiceResponse.error(message: 'some error'))
          end
        end

        it 'does not remove the unmergeable flag' do
          merge_request.approval_state.temporarily_unapprove!

          service.execute(merge_request)

          merge_request.reload

          expect(merge_request.approval_state.temporarily_unapproved?).to be_truthy
        end
      end
    end

    context 'for audit events' do
      let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }
      let_it_be(:merge_request) { create(:merge_request, author: project_bot) }

      include_examples 'audit event logging' do
        let(:operation) { service.execute(merge_request) }
        let(:event_type) { 'merge_request_closed_by_project_bot' }
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
              custom_message: "Closed merge request #{merge_request.title}"
            }
          }
        end
      end
    end
  end
end
