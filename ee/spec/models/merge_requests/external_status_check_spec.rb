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
        expect(ApprovalRules::ExternalApprovalRulePayloadWorker).not_to receive(:perform_async)

        subject
      end
    end
  end

  describe 'failed?' do
    let_it_be(:rule) { create(:external_status_check) }
    let_it_be(:merge_request) { create(:merge_request) }

    let(:project) { merge_request.source_project }

    subject { rule.failed?(merge_request) }

    context 'when last status check response is failed' do
      before do
        create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.diff_head_sha, status: 'passed')
        create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.diff_head_sha, status: 'failed')
      end

      it { is_expected.to be true }
    end

    context 'when last status check response is passed' do
      before do
        create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.diff_head_sha, status: 'failed')
        create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.diff_head_sha, status: 'passed')
      end

      it { is_expected.to be false }
    end

    context 'when there are no status check responses' do
      before do
        merge_request.status_check_responses.delete_all
      end

      it { is_expected.to be false }
    end
  end

  describe 'status' do
    let_it_be(:rule) { create(:external_status_check) }
    let_it_be(:merge_request) { create(:merge_request) }

    let(:project) { merge_request.source_project }

    subject { rule.status(merge_request, merge_request.source_branch_sha) }

    context 'when a rule has a positive status check response' do
      let_it_be(:status_check_response) { create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.source_branch_sha, status: 'passed') }

      it { is_expected.to eq('passed') }

      context 'when a rule also has a positive check response from an old sha' do
        before do
          create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: 'abc1234', status: 'passed')
        end

        it { is_expected.to eq('passed') }
      end
    end

    context 'when a rule has a negative status check response' do
      let_it_be(:status_check_response) { create(:status_check_response, merge_request: merge_request, external_status_check: rule, sha: merge_request.source_branch_sha, status: 'failed') }

      it { is_expected.to eq('failed') }
    end

    context 'when a rule has no status check response' do
      it { is_expected.to eq('pending') }
    end
  end

  describe 'callbacks', :request_store do
    let_it_be(:project) { create(:project) }
    let_it_be(:master_branch) { create(:protected_branch, project: project, name: 'master') }
    let_it_be(:main_branch) { create(:protected_branch, project: project, name: 'main') }
    let_it_be(:external_status_check, reload: true) do
      create(:external_status_check, project: project, name: 'QA', protected_branches: [])
    end

    describe '#audit_add branches after :add' do
      context 'when branch is added from zero branches' do
        let(:action!) { external_status_check.update!(protected_branches: [main_branch]) }
        let(:message) { 'Added protected branch main to QA status check and removed all other branches from status check' }

        it_behaves_like 'audit event queue'
      end

      context 'when another branch is added' do
        before do
          external_status_check.update!(protected_branches: [main_branch])
        end

        let(:action!) { external_status_check.update!(protected_branches: [main_branch, master_branch]) }
        let(:message) { 'Added protected branch master to QA status check' }

        it_behaves_like 'audit event queue'
      end
    end

    describe '#audit_remove branches after :remove' do
      context 'when all the branches are removed' do
        before do
          external_status_check.update!(protected_branches: [main_branch])
        end

        let(:action!) { external_status_check.update!(protected_branches: []) }
        let(:message) { 'Added all branches to QA status check' }

        it_behaves_like 'audit event queue'
      end

      context 'when a branch is removed' do
        before do
          external_status_check.update!(protected_branches: [main_branch, master_branch])
        end

        let(:action!) { external_status_check.update!(protected_branches: [master_branch]) }
        let(:message) { 'Removed protected branch main from QA status check' }

        it_behaves_like 'audit event queue'
      end
    end

    describe '#audit_creation external status check after :create' do
      context 'when protected branches are added' do
        let_it_be(:external_status_check) do
          described_class.new(name: 'QAv2',
                              project: project,
                              external_url: 'https://www.example.com',
                              protected_branch_ids: [main_branch.id, master_branch.id])
        end

        let(:action!) { external_status_check.save! }
        let(:message) { 'Added QAv2 status check with protected branch(es) main, master' }

        it_behaves_like 'audit event queue'
      end

      context 'when all branches are added' do
        let_it_be(:external_status_check) do
          described_class.new(name: 'QAv2',
                              project: project,
                              external_url: 'https://www.example.com',
                              protected_branch_ids: [])
        end

        let(:action!) { external_status_check.save! }
        let(:message) { 'Added QAv2 status check with all branches' }

        it_behaves_like 'audit event queue'
      end
    end

    describe '#audit_creation external status check after :create' do
      let(:action!) { external_status_check.destroy! }
      let(:message) { 'Removed QA status check' }

      it_behaves_like 'audit event queue'
    end
  end
end
