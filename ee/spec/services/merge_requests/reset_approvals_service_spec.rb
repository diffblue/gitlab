# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ResetApprovalsService, feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }

  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true) }

  let(:merge_request) do
    create(:merge_request,
      author: current_user,
      source_project: project,
      source_branch: 'master',
      target_branch: 'feature',
      target_project: project,
      merge_when_pipeline_succeeds: true,
      merge_user: user)
  end

  let(:commits) { merge_request.commits }
  let(:oldrev) { commits.last.id }
  let(:newrev) { commits.first.id }
  let(:owner) { create(:user, username: 'co1') }
  let(:approver) { create(:user, username: 'co2') }
  let(:security) { create(:user) }
  let(:notification_service) { spy('notification_service') }

  def approval_todos(merge_request)
    Todo.where(action: Todo::APPROVAL_REQUIRED, target: merge_request)
  end

  describe "#execute" do
    before do
      stub_licensed_features(multiple_approval_rules: true)
      allow(service).to receive(:execute_hooks)
      allow(NotificationService).to receive(:new) { notification_service }
      project.add_developer(approver)
      project.add_developer(owner)
    end

    context 'as default' do
      before do
        perform_enqueued_jobs do
          merge_request.update!(approver_ids: [approver.id, owner.id, current_user.id])
        end

        create(:approval, merge_request: merge_request, user: approver)
        create(:approval, merge_request: merge_request, user: owner)
      end

      context 'when no_todo_for_approvers feature flag is disabled' do
        before do
          stub_feature_flags(no_todo_for_approvers: false)
        end

        it 'resets all approvals and creates new todos for approvers' do
          service.execute("refs/heads/master", newrev)
          merge_request.reload

          expect(merge_request.approvals).to be_empty
          expect(approval_todos(merge_request).map(&:user)).to contain_exactly(approver, owner)
        end
      end

      context 'when no_todo_for_approvers feature flag is enabled' do
        before do
          stub_feature_flags(no_todo_for_approvers: true)
        end

        it 'resets all approvals and does not create new todos for approvers' do
          service.execute("refs/heads/master", newrev)
          merge_request.reload

          expect(merge_request.approvals).to be_empty
          expect(approval_todos(merge_request).map(&:user)).to be_empty
        end
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { service.execute('refs/heads/master', newrev) }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { service.execute('refs/heads/master', newrev) }
      end
    end

    context 'when skip_reset_checks: true' do
      before do
        perform_enqueued_jobs do
          merge_request.update!(approver_ids: [approver.id, owner.id, current_user.id])
        end

        create(:approval, merge_request: merge_request, user: approver)
        create(:approval, merge_request: merge_request, user: owner)
      end

      it 'deletes all approvals directly without additional checks or side-effects' do
        expect(service).to receive(:delete_approvals).and_call_original
        expect(service).not_to receive(:reset_approvals)

        service.execute("refs/heads/master", newrev, skip_reset_checks: true)

        merge_request.reload

        expect(merge_request.approvals).to be_empty
        expect(approval_todos(merge_request)).to be_empty
      end

      it 'will delete approvals in situations where a false setting would not' do
        expect(service).to receive(:reset_approvals?).and_return(false)

        expect do
          service.execute("refs/heads/master", newrev)
          merge_request.reload
        end.not_to change { merge_request.approvals.length }

        allow(service).to receive(:reset_approvals?).and_call_original
        expect(service).to receive(:delete_approvals).and_call_original
        expect(service).not_to receive(:reset_approvals)

        service.execute("refs/heads/master", newrev, skip_reset_checks: true)

        merge_request.reload

        expect(merge_request.approvals).to be_empty
        expect(approval_todos(merge_request)).to be_empty
      end
    end

    context 'with selective code owner removals' do
      let_it_be(:project) do
        create(:project,
          :custom_repo,
          files: { 'CODEOWNERS' => "*.rb @co1\n*.js @co2", 'file.rb' => '1' },
          reset_approvals_on_push: false,
          project_setting_attributes: { selective_code_owner_removals: true })
      end

      let_it_be(:feature_sha1) { project.repository.create_file(current_user, "another.rb", "2", message: "2", branch_name: 'feature') }
      let_it_be(:feature_sha2) { project.repository.create_file(current_user, "some.js", "3", message: "3", branch_name: 'feature') }
      let_it_be(:feature_sha3) { project.repository.create_file(current_user, "last.rb", "4", message: "4", branch_name: 'feature') }
      let_it_be(:merge_request) do
        create(:merge_request,
          author: current_user,
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master'
        )
      end

      before do
        ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
        perform_enqueued_jobs do
          merge_request.update!(approver_ids: [approver.id, owner.id, current_user.id])
        end
        create(:any_approver_rule, merge_request: merge_request, users: [approver, owner, security])

        create(:approval, merge_request: merge_request, user: security)
        create(:approval, merge_request: merge_request, user: approver)
        create(:approval, merge_request: merge_request, user: owner)

        merge_request.approval_rules.regular.each do |rule|
          rule.users = [security]
        end
      end

      it 'resets code owner approvals with changes' do
        service.execute("feature", feature_sha3)
        merge_request.reload

        expect(merge_request.approvals.count).to be(2)
        expect(merge_request.approvals.map(&:user_id)).to contain_exactly(approver.id, security.id)
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { service.execute('feature', feature_sha3) }
      end

      it_behaves_like 'triggers GraphQL subscription mergeRequestApprovalStateUpdated' do
        let(:action) { service.execute('feature', feature_sha3) }
      end
    end
  end
end
