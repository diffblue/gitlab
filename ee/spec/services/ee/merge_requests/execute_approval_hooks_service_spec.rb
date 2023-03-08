# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ExecuteApprovalHooksService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    context 'with remaining approvals' do
      it 'fires an approval webhook' do
        expect(merge_request).to receive(:approvals_left).and_return(5)
        expect(service).to receive(:execute_hooks).with(merge_request, 'approval')

        service.execute(merge_request)
      end

      it 'does not send an email' do
        expect(merge_request).to receive(:approvals_left).and_return(5)
        expect(service).not_to receive(:notification_service)

        service.execute(merge_request)
      end
    end

    context 'with required approvals' do
      let(:notification_service) { NotificationService.new }

      before do
        allow(merge_request).to receive(:approvals_left).and_return(0)
        allow(service).to receive(:execute_hooks)
        allow(service).to receive(:notification_service).and_return(notification_service)
      end

      it 'fires an approved webhook' do
        expect(service).to receive(:execute_hooks).with(merge_request, 'approved')

        service.execute(merge_request)
      end

      it 'sends an email' do
        expect(notification_service).to receive_message_chain(:async, :approve_mr).with(merge_request, user)

        service.execute(merge_request)
      end
    end
  end
end
