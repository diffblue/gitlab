# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateService, :mailer, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:merge_request) do
    create(
      :merge_request,
      :simple,
      title: 'Old title',
      description: "FYI #{user2.to_reference}",
      assignee_id: user3.id,
      source_project: project,
      author: create(:user)
    )
  end

  let(:no_todo_for_approvers_ff_enabled) { true }

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
  end

  describe '#execute' do
    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { merge_request }
      let(:parent) { project }
    end

    it_behaves_like 'service with multiple reviewers' do
      let(:opts) { {} }
      let(:execute) { update_merge_request(opts) }
    end

    def update_merge_request(opts)
      described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
    end

    context 'when code owners changes' do
      let(:code_owner) { create(:user) }

      before do
        project.add_maintainer(code_owner)

        allow(merge_request).to receive(:code_owners).and_return([], [code_owner])
      end

      it 'does not create any todos' do
        expect do
          update_merge_request(title: 'New title')
        end.not_to change { Todo.count }
      end

      it 'does not send any emails' do
        expect do
          update_merge_request(title: 'New title')
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'when approvals_before_merge changes' do
      using RSpec::Parameterized::TableSyntax

      where(:project_value, :mr_before_value, :mr_after_value, :result) do
        3 | 4   | 5   | 5
        3 | 4   | nil | 3
        3 | nil | 5   | 5
      end

      with_them do
        let(:project) { create(:project, :repository, approvals_before_merge: project_value) }

        it "does not update" do
          merge_request.update!(approvals_before_merge: mr_before_value)
          rule = create(:approval_merge_request_rule, merge_request: merge_request)

          update_merge_request(approvals_before_merge: mr_after_value)

          expect(rule.reload.approvals_required).to eq(0)
        end
      end
    end

    context 'merge' do
      let(:opts) { { merge: merge_request.diff_head_sha } }

      context 'when not approved' do
        before do
          merge_request.update!(approvals_before_merge: 1)

          perform_enqueued_jobs do
            update_merge_request(opts)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it { expect(@merge_request).to be_valid }
        it { expect(@merge_request.state).to eq('opened') }
      end

      context 'when approved' do
        before do
          merge_request.update!(approvals_before_merge: 1)
          merge_request.approvals.create!(user: user)

          perform_enqueued_jobs do
            update_merge_request(opts)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it { expect(@merge_request).to be_valid }

        it 'is in the "merge" state', :sidekiq_might_not_need_inline do
          expect(@merge_request.state).to eq('merged')
        end
      end
    end

    context 'when the approvers change' do
      let(:existing_approver) { create(:user) }
      let(:removed_approver) { create(:user) }
      let(:new_approver) { create(:user) }

      before do
        stub_feature_flags(no_todo_for_approvers: no_todo_for_approvers_ff_enabled)

        project.add_developer(existing_approver)
        project.add_developer(removed_approver)
        project.add_developer(new_approver)

        perform_enqueued_jobs do
          update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
        end

        Todo.where(action: Todo::APPROVAL_REQUIRED).destroy_all # rubocop: disable Cop/DestroyAll
        ActionMailer::Base.deliveries.clear
      end

      context 'when an approver is added and an approver is removed' do
        before do
          perform_enqueued_jobs do
            update_merge_request(approver_ids: [new_approver, existing_approver].map(&:id).join(','))
          end
        end

        context 'when no_todo_for_approvers feature flag is disabled' do
          let(:no_todo_for_approvers_ff_enabled) { false }

          it 'adds todos for and sends emails to the new approvers' do
            expect(Todo.where(user: new_approver, action: Todo::APPROVAL_REQUIRED)).not_to be_empty
            should_email(new_approver)
          end
        end

        context 'when no_todo_for_approvers feature flag is enabled' do
          let(:no_todo_for_approvers_ff_enabled) { true }

          it 'does not add todos for or send emails to the new approvers' do
            expect(Todo.where(user: new_approver, action: Todo::APPROVAL_REQUIRED)).to be_empty
            should_not_email(new_approver)
          end
        end

        it 'does not add todos for or send emails to the existing approvers' do
          expect(Todo.where(user: existing_approver, action: Todo::APPROVAL_REQUIRED)).to be_empty
          should_not_email(existing_approver)
        end

        it 'does not add todos for or send emails to the removed approvers' do
          expect(Todo.where(user: removed_approver, action: Todo::APPROVAL_REQUIRED)).to be_empty
          should_not_email(removed_approver)
        end
      end

      context 'when the approvers are set to the same values' do
        it 'does not create any todos' do
          expect do
            update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
          end.not_to change { Todo.count }
        end

        it 'does not send any emails' do
          expect do
            update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'updating target_branch' do
      let(:existing_approver) { create(:user) }
      let(:new_approver) { create(:user) }

      before do
        stub_feature_flags(no_todo_for_approvers: no_todo_for_approvers_ff_enabled)

        project.add_developer(existing_approver)
        project.add_developer(new_approver)

        perform_enqueued_jobs do
          update_merge_request(approver_ids: "#{existing_approver.id},#{new_approver.id}")
        end

        merge_request.target_project.update!(reset_approvals_on_push: true)
        merge_request.approvals.create!(user_id: existing_approver.id)
      end

      it 'resets approvals when target_branch is changed' do
        update_merge_request(target_branch: 'video')

        expect(merge_request.reload.approvals).to be_empty
      end

      context 'when no_todo_for_approvers feature flag is disabled' do
        let(:no_todo_for_approvers_ff_enabled) { false }

        it 'creates new todos for the approvers' do
          expect(Todo.where(action: Todo::APPROVAL_REQUIRED).map(&:user)).to contain_exactly(new_approver, existing_approver)
        end
      end

      context 'when no_todo_for_approvers feature flag is enabled' do
        let(:no_todo_for_approvers_ff_enabled) { true }

        it 'does not create new todos for the approvers' do
          expect(Todo.where(action: Todo::APPROVAL_REQUIRED)).to be_empty
        end
      end
    end

    context 'updating blocking merge requests' do
      it 'delegates to MergeRequests::UpdateBlocksService' do
        expect(MergeRequests::UpdateBlocksService)
          .to receive(:extract_params!)
          .and_return(:extracted_params)

        expect_next_instance_of(MergeRequests::UpdateBlocksService) do |service|
          expect(service.merge_request).to eq(merge_request)
          expect(service.current_user).to eq(user)
          expect(service.params).to eq(:extracted_params)

          expect(service).to receive(:execute)
        end

        update_merge_request({})
      end
    end

    context 'reset_approval_rules_to_defaults param' do
      let!(:existing_any_rule) { create(:any_approver_rule, merge_request: merge_request) }
      let!(:existing_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }
      let(:rules) { merge_request.reload.approval_rules }

      shared_examples_for 'undeletable existing approval rules' do
        it 'does not delete existing approval rules' do
          aggregate_failures do
            expect(rules).not_to be_empty
            expect(rules).to include(existing_any_rule)
            expect(rules).to include(existing_rule)
          end
        end
      end

      context 'when approval rules can be overridden' do
        before do
          merge_request.project.update!(disable_overriding_approvers_per_merge_request: false)
        end

        context 'when not set' do
          before do
            update_merge_request({})
          end

          it_behaves_like 'undeletable existing approval rules'
        end

        context 'when set to false' do
          before do
            update_merge_request(reset_approval_rules_to_defaults: false)
          end

          it_behaves_like 'undeletable existing approval rules'
        end

        context 'when set to true' do
          context 'and approval_rules_attributes param is not set' do
            before do
              update_merge_request(reset_approval_rules_to_defaults: true)
            end

            it 'deletes existing approval rules' do
              expect(rules).to be_empty
            end
          end

          context 'and approval_rules_attributes param is set' do
            before do
              update_merge_request(
                reset_approval_rules_to_defaults: true,
                approval_rules_attributes: [{ name: 'New Rule', approvals_required: 1 }]
              )
            end

            it 'deletes existing approval rules and creates new one' do
              aggregate_failures do
                expect(rules.size).to eq(1)
                expect(rules).not_to include(existing_any_rule)
                expect(rules).not_to include(existing_rule)
              end
            end
          end
        end
      end

      context 'when approval rules cannot be overridden' do
        before do
          merge_request.project.update!(disable_overriding_approvers_per_merge_request: true)
          update_merge_request(reset_approval_rules_to_defaults: true)
        end

        it_behaves_like 'undeletable existing approval rules'
      end
    end

    context 'when called inside an ActiveRecord transaction' do
      it 'does not attempt to update code owner approval rules' do
        expect(::MergeRequests::SyncCodeOwnerApprovalRulesWorker).not_to receive(:perform_async)

        update_merge_request(title: 'Title')
      end
    end

    context 'updating reviewer_ids' do
      it 'updates the tracking when user ids are valid' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_users_review_requested)
          .with(users: [user, user2])

        update_merge_request(reviewer_ids: [user.id, user2.id])
      end
    end

    describe 'capture suggested_reviewer_ids', feature_category: :workflow_automation do
      shared_examples 'not capturing suggested_reviewer_ids' do
        it 'does not capture the suggested_reviewer_ids and raise update error', :aggregate_failures do
          expect(MergeRequests::CaptureSuggestedReviewersAcceptedWorker).not_to receive(:perform_async)

          expect { update_merge_request(opts) }.not_to raise_error
        end
      end

      context 'when reviewer_ids is present' do
        context 'when suggested_reviewer_ids is present' do
          let(:opts) { { reviewer_ids: [user.id, user2.id], suggested_reviewer_ids: [user.id] } }

          it 'captures the suggested_reviewer_ids and does not raise update error', :aggregate_failures do
            expect(MergeRequests::CaptureSuggestedReviewersAcceptedWorker)
              .to receive(:perform_async)
              .with(merge_request.id, [user.id])

            expect { update_merge_request(opts) }.not_to raise_error
          end
        end

        context 'when suggested_reviewer_ids is blank' do
          let(:opts) { { reviewer_ids: [user.id, user2.id] } }

          it_behaves_like 'not capturing suggested_reviewer_ids'
        end
      end

      context 'when reviewer_ids is blank' do
        let(:opts) { { reviewer_ids: [], suggested_reviewer_ids: [user.id] } }

        it_behaves_like 'not capturing suggested_reviewer_ids'
      end
    end
  end
end
