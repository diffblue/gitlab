# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateApprovalEventService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    it 'creates approve MR event' do
      expect_next_instance_of(EventCreateService) do |instance|
        expect(instance).to receive(:approve_mr)
          .with(merge_request, user)
      end

      service.execute(merge_request)
    end

    context 'for approvals metrics calculation' do
      context 'when code_review_analytics project feature is available' do
        before do
          stub_licensed_features(code_review_analytics: true)
        end

        it 'schedules RefreshApprovalsData' do
          expect(::Analytics::RefreshApprovalsData)
            .to receive_message_chain(:new, :execute)

          service.execute(merge_request)
        end
      end

      context 'when code_review_analytics is not available' do
        before do
          stub_licensed_features(code_review_analytics: false)
        end

        it 'does not schedule for RefreshApprovalsData' do
          expect(::Analytics::RefreshApprovalsData).not_to receive(:new)

          service.execute(merge_request)
        end
      end
    end
  end
end
