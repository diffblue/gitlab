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
        subject.execute
        expect(Gitlab::Audit::Auditor).to have_received(:audit) do |args|
          expect(args[:name]).to eq('delete_merge_request')
          expect(args[:message]).to eq("Removed MergeRequest(#{merge_request.title} with IID: " \
                                       "#{merge_request.iid} and ID: #{merge_request.id})")
        end
      end
    end

    context 'when merge request is merged' do
      before do
        allow(merge_request).to receive(:merged?).and_return(true)
        allow(merge_request).to receive_message_chain(:labels, :pluck_titles).and_return(%w[label1 label2])
        allow(merge_request).to receive(:approved_by_user_ids).and_return([1, 2])
        allow(merge_request).to receive_message_chain(:metrics, :merged_by_id).and_return(3)
        allow(merge_request).to receive_message_chain(:commits, :committer_user_ids).and_return([4, 5])
      end

      it 'audits a merged_merge_request_deleted event' do
        subject.execute
        expect(Gitlab::Audit::Auditor).to have_received(:audit).with(
          hash_including(name: 'merged_merge_request_deleted'))
      end

      it 'includes additional details in the message' do
        subject.execute
        expect(Gitlab::Audit::Auditor).to have_received(:audit) do |args|
          expected_message = "Removed MergeRequest(#{merge_request.title} with IID: #{merge_request.iid} " \
                             "and ID: #{merge_request.id}), labels: label1 and label2, " \
                             "approved_by_user_ids: 1 and 2, " \
                             "merged_by_user_id: 3, committer_user_ids: 4 and 5"
          expect(args[:message]).to eq(expected_message)
        end
      end
    end
  end
end
