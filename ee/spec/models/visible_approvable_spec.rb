# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VisibleApprovable do
  let(:resource) { create(:merge_request, source_project: project) }
  let!(:project) { create(:project, :repository) }
  let!(:user) { project.creator }

  describe '#overall_approvers' do
    let(:approver) { create(:user) }
    let(:code_owner) { build(:user) }

    let!(:project_regular_rule) { create(:approval_project_rule, project: project, users: [approver]) }
    let!(:code_owner_rule) { create(:code_owner_rule, merge_request: resource, users: [code_owner]) }

    before do
      project.add_developer(approver)
      project.add_developer(code_owner)
    end

    subject { resource.overall_approvers }

    it 'returns a list of all the project approvers' do
      is_expected.to contain_exactly(approver, code_owner)
    end

    context 'when exclude_code_owners is true' do
      subject { resource.overall_approvers(exclude_code_owners: true) }

      it 'excludes code owners' do
        is_expected.to contain_exactly(approver)
      end
    end

    context 'when approvers are overwritten' do
      let!(:merge_request_regular_rule) { create(:approval_merge_request_rule, merge_request: resource, users: [create(:user)]) }

      it 'returns the list of all the merge request level approvers' do
        is_expected.to contain_exactly(*merge_request_regular_rule.users, code_owner)
      end
    end

    context 'when author is an approver' do
      let!(:approver) { resource.author }

      it 'excludes author if author cannot approve' do
        project.update!(merge_requests_author_approval: false)
        mr = resource.class.find(resource.id)

        expect(mr.overall_approvers).not_to include(approver)
      end

      it 'includes author if author is able to approve' do
        project.update!(merge_requests_author_approval: true)
        mr = resource.class.find(resource.id)

        expect(mr.overall_approvers).to include(approver)
      end
    end

    context 'when a committer is an approver' do
      let!(:approver) { create(:user, email: resource.commits.without_merge_commits.first.committer_email) }

      it 'excludes the committer if committers cannot approve' do
        project.update!(merge_requests_disable_committers_approval: true)

        is_expected.not_to include(approver)
      end

      it 'includes the committer if committers are able to approve' do
        project.update!(merge_requests_disable_committers_approval: false)

        is_expected.to include(approver)
      end
    end
  end

  describe '#authors_can_approve?' do
    subject { resource.authors_can_approve? }

    it 'returns false when merge_requests_author_approval flag is off' do
      is_expected.to be_falsey
    end

    it 'returns true when merge_requests_author_approval flag is turned on' do
      project.update!(merge_requests_author_approval: true)

      is_expected.to be_truthy
    end
  end
end
