# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ApprovalService do
  describe '#execute' do
    let(:user)          { create(:user) }
    let(:merge_request) { create(:merge_request) }
    let(:project)       { merge_request.project }
    let!(:todo)         { create(:todo, user: user, project: project, target: merge_request) }

    subject(:service) { described_class.new(project: project, current_user: user) }

    before do
      project.add_developer(user)
    end

    context 'with invalid approval' do
      before do
        allow(merge_request.approvals).to receive(:new).and_return(double(save: false))
      end

      it 'does not reset approvals cache' do
        expect(merge_request).not_to receive(:reset_approval_cache!)

        service.execute(merge_request)
      end
    end

    context 'with valid approval' do
      it 'resets the cache for approvals' do
        expect(merge_request).to receive(:reset_approval_cache!)

        service.execute(merge_request)
      end

      it 'creates an approval note' do
        allow(merge_request).to receive(:approvals_left).and_return(1)

        expect(SystemNoteService).to receive(:approve_mr).with(merge_request, user)

        service.execute(merge_request)
      end

      it 'marks pending todos as done' do
        allow(merge_request).to receive(:approvals_left).and_return(1)

        service.execute(merge_request)

        expect(todo.reload).to be_done
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'merge_request_approval_operation',
          stream_only: true,
          author: user,
          scope: merge_request.project,
          target: merge_request,
          message: 'Approved merge request'
        }
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

        service.execute(merge_request)
      end

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
          expect(merge_request).to receive(:approvals_left).and_return(0)
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

      context 'async_after_approval feature flag is disabled' do
        before do
          stub_feature_flags(async_after_approval: false)
        end

        it 'creates approve MR event' do
          expect_next_instance_of(EventCreateService) do |instance|
            expect(instance).to receive(:approve_mr)
              .with(merge_request, user)
          end

          service.execute(merge_request)
        end

        context 'approvals metrics calculation' do
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

    context 'when project requires force auth for approval' do
      before do
        project.update!(require_password_to_approve: true)
      end
      context 'when password not specified' do
        it 'does not update the approvals' do
          expect { service.execute(merge_request) }.not_to change { merge_request.approvals.size }
        end
      end

      context 'when incorrect password is specified' do
        let(:params) do
          { approval_password: 'incorrect' }
        end

        it 'does not update the approvals' do
          service_with_params = described_class.new(project: project, current_user: user, params: params)

          expect { service_with_params.execute(merge_request) }.not_to change { merge_request.approvals.size }
        end
      end

      context 'when correct password is specified' do
        let(:params) do
          { approval_password: user.password }
        end

        it 'approves the merge request' do
          service_with_params = described_class.new(project: project, current_user: user, params: params)

          expect { service_with_params.execute(merge_request) }.to change { merge_request.approvals.size }
        end
      end
    end
  end
end
