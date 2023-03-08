# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RemoveApprovalService, feature_category: :code_review_workflow do
  describe '#execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project, approvals_before_merge: 1) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    def execute!
      service.execute(merge_request)
    end

    context 'with a user who has approved' do
      before do
        project.add_developer(create(:user))
        merge_request.update!(approvals_before_merge: 2)
        merge_request.approvals.create!(user: user)
      end

      it 'removes the approval' do
        expect { execute! }.to change { merge_request.approvals.size }.from(1).to(0)
      end

      it 'creates an unapproval note' do
        expect(SystemNoteService).to receive(:unapprove_mr)

        execute!
      end

      it 'fires an unapproval webhook' do
        expect(service).to receive(:execute_hooks).with(merge_request, 'unapproval')

        execute!
      end

      it 'does not send a notification' do
        expect(service).not_to receive(:notification_service)

        execute!
      end

      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        execute!
      end
    end
  end
end
