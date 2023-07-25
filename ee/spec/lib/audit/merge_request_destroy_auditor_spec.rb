# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::MergeRequestDestroyAuditor, feature_category: :audit_events do
  let(:current_user) { create(:user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  subject { described_class.new(merge_request, current_user) }

  before do
    allow(Gitlab::Audit::Auditor).to receive(:audit)
  end

  describe '#execute' do
    context 'when current_user is nil' do
      let(:current_user) { nil }

      it 'does not audit the event' do
        subject.execute
        expect(Gitlab::Audit::Auditor).not_to have_received(:audit)
      end
    end

    context 'when merge request is not merged' do
      it 'audits a delete_merge_request event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
          name: 'delete_merge_request',
          message: "Removed MergeRequest(#{merge_request.title} with IID: " \
                   "#{merge_request.iid} and ID: #{merge_request.id})"
        ))

        subject.execute
      end
    end

    context 'when merge request is merged' do
      before do
        allow(merge_request).to receive(:merged?).and_return(true)
      end

      it 'audits a merged_merge_request_deleted event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
          name: 'merged_merge_request_deleted',
          message: "Removed MergeRequest(#{merge_request.title} with IID: " \
                   "#{merge_request.iid} and ID: #{merge_request.id})"
        ))

        subject.execute
      end

      context 'when metrics is not present' do
        before do
          allow(merge_request).to receive(:metrics).and_return(nil)
        end

        it 'does not include merged_by_user_id in the message' do
          expect(Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
            message: "Removed MergeRequest(#{merge_request.title} with IID: " \
                     "#{merge_request.iid} and ID: #{merge_request.id})"
          ))

          subject.execute
        end
      end
    end
  end
end
