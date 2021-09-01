# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ExternalStatusCheck, type: :model do
  subject { build(:external_status_check) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_and_belong_to_many(:protected_branches) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:external_url) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_uniqueness_of(:external_url).scoped_to(:project_id) }

    describe 'protected_branches_must_belong_to_project' do
      let(:check) { build(:external_status_check, protected_branches: [create(:protected_branch)]) }

      it 'is invalid' do
        expect(check).to be_invalid
        expect(check.errors.messages[:base]).to eq ['all protected branches must exist within the project']
      end
    end
  end

  describe 'to_h' do
    it 'returns the correct information' do
      expect(subject.to_h).to eq({ id: subject.id, name: subject.name, external_url: subject.external_url })
    end
  end

  describe 'applicable_to_branch' do
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:check_belonging_to_different_project) { create(:external_status_check) }
    let_it_be(:check_with_no_protected_branches) { create(:external_status_check, project: merge_request.project, protected_branches: []) }
    let_it_be(:check_with_applicable_protected_branches) { create(:external_status_check, project: merge_request.project, protected_branches: [create(:protected_branch, name: merge_request.target_branch, project: merge_request.project)]) }
    let_it_be(:check_with_non_applicable_protected_branches) { create(:external_status_check, project: merge_request.project, protected_branches: [create(:protected_branch, name: 'testbranch', project: merge_request.project)]) }

    it 'returns the correct collection of checks' do
      expect(merge_request.project.external_status_checks.applicable_to_branch(merge_request.target_branch)).to contain_exactly(check_with_no_protected_branches, check_with_applicable_protected_branches)
    end
  end

  describe 'async_execute' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:data) do
      {
        object_attributes: {
          target_branch: 'test'
        }
      }
    end

    subject { check.async_execute(data) }

    context 'when list of protected branches is empty' do
      let_it_be(:check) { create(:external_status_check, project: merge_request.project) }

      it 'enqueues the status check' do
        expect(ApprovalRules::ExternalApprovalRulePayloadWorker).to receive(:perform_async).once

        subject
      end
    end

    context 'when data target branch matches a protected branch' do
      let_it_be(:check) { create(:external_status_check, project: merge_request.project, protected_branches: [create(:protected_branch, name: 'test', project: merge_request.project)]) }

      it 'enqueues the status check' do
        expect(ApprovalRules::ExternalApprovalRulePayloadWorker).to receive(:perform_async).once

        subject
      end
    end

    context 'when data target branch does not match a protected branch' do
      let_it_be(:check) { create(:external_status_check, project: merge_request.project, protected_branches: [create(:protected_branch, name: 'new-branch', project: merge_request.project)]) }

      it 'does not enqueue the status check' do
        expect(ApprovalRules::ExternalApprovalRulePayloadWorker).to receive(:perform_async).never

        subject
      end
    end
  end

  describe 'approved?' do
    let_it_be(:rule) { create(:external_status_check) }
    let_it_be(:merge_request) { create(:merge_request) }

    let(:project) { merge_request.source_project }

    subject { rule.approved?(merge_request, merge_request.source_branch_sha) }

    context 'when a rule has a positive status check response' do
      let_it_be(:status_check_response) { create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.source_branch_sha) }

      it { is_expected.to be true }

      context 'when a rule also has a positive check response from an old sha' do
        before do
          create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: 'abc1234')
        end

        it { is_expected.to be true }
      end
    end

    context 'when a rule has no positive status check response' do
      it { is_expected.to be false }
    end

    context 'when a rule has a positive status check response from an old sha' do
      before do
        create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: 'abc123')
      end

      it { is_expected.to be false }
    end
  end
end
