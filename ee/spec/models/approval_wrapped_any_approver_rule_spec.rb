# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalWrappedAnyApproverRule do
  let(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request, rule) }

  let(:rule) do
    create(:any_approver_rule, merge_request: merge_request, approvals_required: 2)
  end

  let(:approver1) { create(:user) }
  let(:approver2) { create(:user) }

  before do
    create(:approval, merge_request: merge_request, user: approver1)
    create(:approval, merge_request: merge_request, user: approver2)
  end

  describe '#approvals_approvers' do
    it 'contains every approved user' do
      expect(subject.approved_approvers).to contain_exactly(approver1, approver2)
    end

    context 'when an author and a committer approved' do
      before do
        merge_request.project.update!(
          merge_requests_author_approval: false,
          merge_requests_disable_committers_approval: true
        )

        create(:approval, merge_request: merge_request, user: merge_request.author)

        committer = create(:user, username: 'commiter')
        create(:approval, merge_request: merge_request, user: committer)
        allow(merge_request).to receive(:committers).and_return(User.where(id: committer.id))
      end

      it 'does not contain an author' do
        expect(subject.approved_approvers).to contain_exactly(approver1, approver2)
      end
    end
  end

  it '#approved?' do
    expect(subject.approved?).to eq(true)
  end

  describe "#commented_approvers" do
    it "returns an array" do
      expect(subject.commented_approvers).to be_an(Array)
    end

    it "returns an array of approvers who have commented" do
      create(:note, project: merge_request.project, noteable: merge_request, author: approver1)
      create(:system_note, project: merge_request.project, noteable: merge_request, author: approver2)

      allow(merge_request).to receive(:eligible_for_approval_by?).and_return(true)

      expect(subject.commented_approvers).to include(approver1)
      expect(subject.commented_approvers).not_to include(approver2)
    end
  end
end
