# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::RefreshService, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include UserHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true) }
  let(:forked_project) { fork_project(project, fork_user, repository: true) }

  let(:fork_user) { create(:user) }

  let(:source_branch) { 'between-create-delete-modify-move' }

  let(:merge_request) do
    create(:merge_request,
      source_project: project,
      source_branch: source_branch,
      target_branch: 'master',
      target_project: project)
  end

  let(:another_merge_request) do
    create(:merge_request,
      source_project: project,
      source_branch: source_branch,
      target_branch: 'test',
      target_project: project)
  end

  let(:forked_merge_request) do
    create(:merge_request,
      source_project: forked_project,
      source_branch: source_branch,
      target_branch: 'master',
      target_project: project)
  end

  let(:oldrev) { TestEnv::BRANCH_SHA[source_branch] }
  let(:newrev) { TestEnv::BRANCH_SHA['after-create-delete-modify-move'] } # Pretend source_branch is now updated
  let(:service) { described_class.new(project: project, current_user: current_user) }
  let(:current_user) { merge_request.author }

  subject { service.execute(oldrev, newrev, "refs/heads/#{source_branch}") }

  describe '#execute' do
    it 'checks merge train status' do
      expect_next_instance_of(MergeTrains::CheckStatusService, project, current_user) do |service|
        expect(service).to receive(:execute).with(project, source_branch, newrev)
      end

      subject
    end

    context 'when branch is deleted' do
      let(:newrev) { Gitlab::Git::BLANK_SHA }

      it 'does not check merge train status' do
        expect(MergeTrains::CheckStatusService).not_to receive(:new)

        subject
      end
    end

    describe '#update_approvers_for_target_branch_merge_requests' do
      shared_examples_for 'does not refresh the code owner rules' do
        specify do
          expect(::MergeRequests::SyncCodeOwnerApprovalRules).not_to receive(:new)
          subject
        end
      end

      subject { service.execute(oldrev, newrev, "refs/heads/master") }

      let(:enable_code_owner) { true }
      let!(:protected_branch) { create(:protected_branch, name: 'master', project: project, code_owner_approval_required: true) }
      let(:newrev) { TestEnv::BRANCH_SHA['with-codeowners'] }

      before do
        stub_licensed_features(code_owner_approval_required: true, code_owners: enable_code_owner)
      end

      context 'when the feature flags are enabled' do
        context 'when the branch is protected' do
          context 'when code owners file is updated' do
            let(:irrelevant_merge_request) { another_merge_request }
            let(:relevant_merge_request) { merge_request }

            context 'when not on the merge train' do
              it 'refreshes the code owner rules for all relevant merge requests' do
                fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

                expect(::MergeRequests::SyncCodeOwnerApprovalRules)
                  .to receive(:new).with(relevant_merge_request).and_return(fake_refresh_service)
                expect(fake_refresh_service).to receive(:execute)

                expect(::MergeRequests::SyncCodeOwnerApprovalRules)
                  .not_to receive(:new).with(irrelevant_merge_request)

                subject
              end
            end

            context 'when on the merge train' do
              let(:merge_request) do
                create(:merge_request,
                   :on_train,
                   source_project: project,
                   source_branch: source_branch,
                   target_branch: 'master',
                   target_project: project)
              end

              it_behaves_like 'does not refresh the code owner rules'
            end
          end

          context 'when code owners file is not updated' do
            let(:newrev) { TestEnv::BRANCH_SHA['after-create-delete-modify-move'] }

            it_behaves_like 'does not refresh the code owner rules'
          end

          context 'when the branch is deleted' do
            let(:newrev) { Gitlab::Git::BLANK_SHA }

            it_behaves_like 'does not refresh the code owner rules'
          end

          context 'when the branch is created' do
            let(:oldrev) { Gitlab::Git::BLANK_SHA }

            it_behaves_like 'does not refresh the code owner rules'
          end
        end

        context 'when the branch is not protected' do
          let(:protected_branch) { nil }

          it_behaves_like 'does not refresh the code owner rules'
        end
      end

      context 'when code_owners is disabled' do
        let(:enable_code_owner) { false }

        it_behaves_like 'does not refresh the code owner rules'
      end
    end

    describe '#trigger_suggested_reviewers_fetch' do
      using RSpec::Parameterized::TableSyntax

      where(:project_can_suggest, :merge_request_can_suggest, :triggered) do
        true  | true  | true
        true  | false | false
        false | true  | false
        false | false | false
      end

      with_them do
        before do
          allow(project).to receive(:can_suggest_reviewers?).and_return(project_can_suggest)

          allow(merge_request).to receive(:can_suggest_reviewers?).and_return(merge_request_can_suggest)
          allow(service).to receive(:merge_requests_for_source_branch).and_return([merge_request])
        end

        it do
          if triggered
            expect(::MergeRequests::FetchSuggestedReviewersWorker).to receive(:perform_async).with(merge_request.id)
          else
            expect(::MergeRequests::FetchSuggestedReviewersWorker).not_to receive(:perform_async).with(merge_request.id)
          end

          subject
        end
      end
    end

    describe '#update_approvers_for_source_branch_merge_requests' do
      let(:owner) { create(:user, username: 'default-codeowner') }
      let(:current_user) { merge_request.author }
      let(:service) { described_class.new(project: project, current_user: current_user) }
      let(:enable_code_owner) { true }
      let(:enable_report_approver_rules) { true }
      let(:todo_service) { double(:todo_service, add_merge_request_approvers: true) }
      let(:notification_service) { double(:notification_service) }

      before do
        stub_licensed_features(code_owners: enable_code_owner)
        stub_licensed_features(report_approver_rules: enable_report_approver_rules)

        allow(service).to receive(:mark_pending_todos_done)
        allow(service).to receive(:notify_about_push)
        allow(service).to receive(:execute_hooks)
        allow(service).to receive(:todo_service).and_return(todo_service)
        allow(service).to receive(:notification_service).and_return(notification_service)

        group.add_maintainer(fork_user)

        merge_request
        another_merge_request
        forked_merge_request
      end

      it 'gets called in a specific order' do
        allow_any_instance_of(MergeRequests::BaseService).to receive(:inspect).and_return(true)
        expect(service).to receive(:reload_merge_requests).ordered
        expect(service).to receive(:update_approvers_for_source_branch_merge_requests).ordered
        expect(service).to receive(:reset_approvals_for_merge_requests).ordered

        subject
      end

      context "creating approval_rules" do
        shared_examples_for 'creates an approval rule based on current diff' do
          it "creates expected approval rules" do
            expect(another_merge_request.approval_rules.size).to eq(approval_rules_size)
            expect(another_merge_request.approval_rules.first.rule_type).to eq('code_owner')
          end
        end

        before do
          project.repository.create_file(owner, 'CODEOWNERS', file, branch_name: 'test', message: 'codeowners')

          subject
        end

        context 'with a non-sectional codeowners file' do
          let_it_be(:file) do
            File.read(Rails.root.join('ee', 'spec', 'fixtures', 'codeowners_example'))
          end

          it_behaves_like 'creates an approval rule based on current diff' do
            let(:approval_rules_size) { 3 }
          end
        end

        context 'with a sectional codeowners file' do
          let_it_be(:file) do
            File.read(Rails.root.join('ee', 'spec', 'fixtures', 'sectional_codeowners_example'))
          end

          it_behaves_like 'creates an approval rule based on current diff' do
            let(:approval_rules_size) { 9 }
          end
        end
      end

      context 'when code owners disabled' do
        let(:enable_code_owner) { false }

        it 'does nothing' do
          expect(::Gitlab::CodeOwners).not_to receive(:for_merge_request)

          subject
        end
      end

      context 'when code owners enabled' do
        let(:relevant_merge_requests) { [merge_request, another_merge_request] }

        it 'refreshes the code owner rules for all relevant merge requests' do
          fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

          relevant_merge_requests.each do |merge_request|
            expect(::MergeRequests::SyncCodeOwnerApprovalRules)
              .to receive(:new).with(merge_request).and_return(fake_refresh_service)
            expect(fake_refresh_service).to receive(:execute)
          end

          subject
        end
      end

      context 'when report_approver_rules enabled, with approval_rule enabled' do
        let(:relevant_merge_requests) { [merge_request, another_merge_request] }

        it 'refreshes the report_approver rules for all relevant merge requests' do
          relevant_merge_requests.each do |merge_request|
            expect_next_instance_of(::MergeRequests::SyncReportApproverApprovalRules, merge_request, current_user) do |service|
              expect(service).to receive(:execute)
            end
          end

          subject
        end
      end
    end

    describe 'Pipelines for merge requests', :sidekiq_inline do
      let(:service) { described_class.new(project: project, current_user: current_user) }
      let(:project) { create(:project, :repository, namespace: group, reset_approvals_on_push: true) }
      let(:current_user) { merge_request.author }

      let(:config) do
        {
          test: {
            stage: 'test',
            script: 'echo',
            only: ['merge_requests']
          }
        }
      end

      before do
        project.add_developer(current_user)
        project.update!(merge_pipelines_enabled: true)
        stub_licensed_features(merge_pipelines: true)
        stub_ci_pipeline_yaml_file(YAML.dump(config))
      end

      it 'creates a merge request pipeline' do
        expect { subject }
          .to change { merge_request.pipelines_for_merge_request.count }.by(1)

        expect(merge_request.all_pipelines.last).to be_merged_result_pipeline
      end

      context 'when MergeRequestUpdateWorker is retried by an exception' do
        it 'does not re-create a duplicate merge request pipeline' do
          expect do
            service.execute(oldrev, newrev, "refs/heads/#{source_branch}")
          end.to change { merge_request.pipelines_for_merge_request.count }.by(1)

          expect do
            service.execute(oldrev, newrev, "refs/heads/#{source_branch}")
          end.not_to change { merge_request.pipelines_for_merge_request.count }
        end
      end
    end

    context 'when user is approver' do
      let_it_be(:user) { create(:user) }

      let(:merge_request) do
        create(:merge_request,
          source_project: project,
          source_branch: 'master',
          target_branch: 'feature',
          target_project: project,
          merge_when_pipeline_succeeds: true,
          merge_user: user)
      end

      let(:forked_project) { fork_project(project, user, repository: true) }
      let(:forked_merge_request) do
        create(:merge_request,
          source_project: forked_project,
          source_branch: 'master',
          target_branch: 'feature',
          target_project: project)
      end

      let(:commits) { merge_request.commits }
      let(:oldrev) { commits.last.id }
      let(:newrev) { commits.first.id }
      let(:approver) { create(:user) }

      let(:no_todo_for_approvers_ff_enabled) { false }

      before do
        stub_feature_flags(no_todo_for_approvers: no_todo_for_approvers_ff_enabled)

        group.add_owner(user)

        merge_request.approvals.create!(user_id: user.id)
        forked_merge_request.approvals.create!(user_id: user.id)

        project.add_developer(approver)

        perform_enqueued_jobs do
          merge_request.update!(approver_ids: [approver].map(&:id).join(','))
          forked_merge_request.update!(approver_ids: [approver].map(&:id).join(','))
        end
      end

      def approval_todos(merge_request)
        Todo.where(action: Todo::APPROVAL_REQUIRED, target: merge_request)
      end

      context 'push to origin repo source branch', :sidekiq_inline do
        let(:notification_service) { spy('notification_service') }

        before do
          allow(service).to receive(:execute_hooks)
          allow(NotificationService).to receive(:new) { notification_service }
        end

        context 'when no_todo_for_approvers feature flag is enabled' do
          let(:no_todo_for_approvers_ff_enabled) { true }

          it 'resets approvals and does not create approval todos for regular and for merge request' do
            service.execute(oldrev, newrev, 'refs/heads/master')
            reload_mrs

            expect(merge_request.approvals).to be_empty
            expect(forked_merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request).map(&:user)).to be_empty
            expect(approval_todos(forked_merge_request)).to be_empty
          end
        end

        context 'when no_todo_for_approvers feature flag is disabled' do
          let(:no_todo_for_approvers_ff_enabled) { false }

          it 'resets approvals and does create approval todos for regular only' do
            service.execute(oldrev, newrev, 'refs/heads/master')
            reload_mrs

            expect(merge_request.approvals).to be_empty
            expect(forked_merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request).map(&:user)).to contain_exactly(approver)
            expect(approval_todos(forked_merge_request)).to be_empty
          end
        end
      end

      context 'push to origin repo target branch' do
        context 'when all MRs to the target branch had diffs' do
          before do
            service.execute(oldrev, newrev, 'refs/heads/feature')
            reload_mrs
          end

          it 'does not reset approvals' do
            expect(merge_request.approvals).not_to be_empty
            expect(forked_merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request)).to be_empty
            expect(approval_todos(forked_merge_request)).to be_empty
          end
        end
      end

      context 'push to fork repo source branch' do
        let(:service) { described_class.new(project: forked_project, current_user: user) }

        def refresh
          allow(service).to receive(:execute_hooks)
          service.execute(oldrev, newrev, 'refs/heads/master')
          reload_mrs
        end

        context 'open fork merge request' do
          context 'when no_todo_for_approvers feature flag is disabled' do
            before do
              stub_feature_flags(no_todo_for_approvers: false)
            end

            it 'resets approvals and creates approval todo in fork', :sidekiq_might_not_need_inline do
              refresh

              expect(merge_request.approvals).not_to be_empty
              expect(forked_merge_request.approvals).to be_empty
              expect(approval_todos(merge_request)).to be_empty
              expect(approval_todos(forked_merge_request).map(&:user)).to contain_exactly(approver)
            end
          end

          context 'when no_todo_for_approvers feature flag is enabled' do
            before do
              stub_feature_flags(no_todo_for_approvers: true)
            end

            it 'resets approvals and does not create approval todo in fork', :sidekiq_might_not_need_inline do
              refresh

              expect(merge_request.approvals).not_to be_empty
              expect(forked_merge_request.approvals).to be_empty
              expect(approval_todos(merge_request)).to be_empty
              expect(approval_todos(forked_merge_request)).to be_empty
            end
          end
        end

        context 'closed fork merge request' do
          before do
            forked_merge_request.close!
          end

          it 'resets approvals', :sidekiq_might_not_need_inline do
            refresh

            expect(merge_request.approvals).not_to be_empty
            expect(forked_merge_request.approvals).to be_empty
            expect(approval_todos(merge_request)).to be_empty
            expect(approval_todos(forked_merge_request)).to be_empty
          end
        end
      end

      context 'push to fork repo target branch' do
        describe 'changes to merge requests' do
          before do
            described_class.new(project: forked_project, current_user: user).execute(oldrev, newrev, 'refs/heads/feature')
            reload_mrs
          end

          it 'does not reset approvals', :sidekiq_might_not_need_inline do
            expect(merge_request.approvals).not_to be_empty
            expect(forked_merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request)).to be_empty
            expect(approval_todos(forked_merge_request)).to be_empty
          end
        end
      end

      context 'push to origin repo target branch after fork project was removed' do
        before do
          forked_project.destroy!
          service.execute(oldrev, newrev, 'refs/heads/feature')
          reload_mrs
        end

        it 'does not reset approvals' do
          expect(merge_request.approvals).not_to be_empty
          expect(forked_merge_request.approvals).not_to be_empty
          expect(approval_todos(merge_request)).to be_empty
          expect(approval_todos(forked_merge_request)).to be_empty
        end
      end

      context 'resetting approvals if they are enabled', :sidekiq_inline do
        context 'when approvals_before_merge is disabled' do
          before do
            project.update!(approvals_before_merge: 0)
            allow(service).to receive(:execute_hooks)
            service.execute(oldrev, newrev, 'refs/heads/master')
            reload_mrs
          end

          context 'when no_todo_for_approvers feature flag is disabled' do
            let(:no_todo_for_approvers_ff_enabled) { false }

            it 'resets approvals and creates approval todo for approver' do
              expect(merge_request.approvals).to be_empty
              expect(approval_todos(merge_request).map(&:user)).to contain_exactly(approver)
            end
          end

          context 'when no_todo_for_approvers feature flag is enabled' do
            let(:no_todo_for_approvers_ff_enabled) { true }

            it 'resets approvals and creates approval todo for approver' do
              expect(merge_request.approvals).to be_empty
              expect(approval_todos(merge_request)).to be_empty
            end
          end
        end

        context 'when reset_approvals_on_push is disabled' do
          before do
            project.update!(reset_approvals_on_push: false)
            allow(service).to receive(:execute_hooks)
            service.execute(oldrev, newrev, 'refs/heads/master')
            reload_mrs
          end

          it 'does not reset approvals' do
            expect(merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request)).to be_empty
          end
        end

        context 'when the rebase_commit_sha on the MR matches the pushed SHA' do
          before do
            merge_request.update!(rebase_commit_sha: newrev)
            allow(service).to receive(:execute_hooks)
            service.execute(oldrev, newrev, 'refs/heads/master')
            reload_mrs
          end

          it 'does not reset approvals' do
            expect(merge_request.approvals).not_to be_empty
            expect(approval_todos(merge_request)).to be_empty
          end
        end

        context 'when there are approvals', :sidekiq_inline do
          context 'closed merge request' do
            before do
              merge_request.close!
              allow(service).to receive(:execute_hooks)
              service.execute(oldrev, newrev, 'refs/heads/master')
              reload_mrs
            end

            it 'resets the approvals' do
              expect(merge_request.approvals).to be_empty
              expect(approval_todos(merge_request)).to be_empty
            end
          end

          context 'opened merge request' do
            before do
              allow(service).to receive(:execute_hooks)
              service.execute(oldrev, newrev, 'refs/heads/master')
              reload_mrs
            end

            context 'when no_todo_for_approvers feature flag is disabled' do
              let(:no_todo_for_approvers_ff_enabled) { false }

              it 'resets the approvals' do
                expect(merge_request.approvals).to be_empty
                expect(approval_todos(merge_request).map(&:user)).to contain_exactly(approver)
              end
            end

            context 'when no_todo_for_approvers feature flag is enabled' do
              let(:no_todo_for_approvers_ff_enabled) { true }

              it 'resets the approvals' do
                expect(merge_request.approvals).to be_empty
                expect(approval_todos(merge_request)).to be_empty
              end
            end
          end
        end
      end

      def reload_mrs
        merge_request.reload
        forked_merge_request.reload
      end
    end
  end

  describe '#abort_ff_merge_requests_with_when_pipeline_succeeds' do
    let_it_be(:project) { create(:project, :repository, merge_method: 'ff') }
    let_it_be(:author) { create_user_from_membership(project, :developer) }
    let_it_be(:user) { create(:user) }

    let_it_be(:merge_request, refind: true) do
      create(:merge_request,
             author: author,
             source_project: project,
             source_branch: 'feature',
             target_branch: 'master',
             target_project: project,
             auto_merge_enabled: true,
             merge_user: user)
    end

    let_it_be(:newrev) do
      project
        .repository
        .create_file(user, 'test1.txt', 'Test data',
                     message: 'Test commit', branch_name: 'master')
    end

    let_it_be(:oldrev) do
      project
        .repository
        .commit(newrev)
        .parent_id
    end

    let(:refresh_service) { described_class.new(project: project, current_user: user) }

    before do
      merge_request.auto_merge_strategy = auto_merge_strategy
      merge_request.save!

      refresh_service.execute(oldrev, newrev, 'refs/heads/master')
      merge_request.reload
    end

    context 'with add to merge train when pipeline succeeds strategy' do
      let(:auto_merge_strategy) do
        AutoMergeService::STRATEGY_ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS
      end

      it_behaves_like 'maintained merge requests for MWPS'
    end

    context 'with merge train strategy' do
      let(:auto_merge_strategy) { AutoMergeService::STRATEGY_MERGE_TRAIN }

      it_behaves_like 'maintained merge requests for MWPS'
    end
  end
end
