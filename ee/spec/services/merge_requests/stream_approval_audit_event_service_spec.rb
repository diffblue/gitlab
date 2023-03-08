# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::StreamApprovalAuditEventService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    it 'sends the audit streaming event' do
      audit_context = {
        name: 'merge_request_approval_operation',
        stream_only: true,
        author: user,
        scope: merge_request.project,
        target: merge_request,
        message: 'Approved merge request'
      }
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original

      service.execute(merge_request)
    end
  end
end
