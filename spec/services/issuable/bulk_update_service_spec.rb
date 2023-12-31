# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::BulkUpdateService, feature_category: :team_planning do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }

  def bulk_update(issuables, extra_params = {})
    bulk_update_params = extra_params
      .reverse_merge(issuable_ids: Array(issuables).map(&:id).join(','))

    type = Array(issuables).first.model_name.param_key
    Issuable::BulkUpdateService.new(parent, user, bulk_update_params).execute(type)
  end

  shared_examples 'updates milestones' do
    it 'succeeds' do
      result = bulk_update(issuables, milestone_id: milestone.id)

      expect(result.success?).to be_truthy
      expect(result.payload[:count]).to eq(issuables.count)
    end

    it 'updates the issuables milestone' do
      bulk_update(issuables, milestone_id: milestone.id)

      issuables.each do |issuable|
        expect(issuable.reload.milestone).to eq(milestone)
      end
    end
  end

  shared_examples 'updates confidentiality' do
    it 'succeeds' do
      result = bulk_update(issuables, confidential: true)

      expect(result.success?).to be_truthy
      expect(result.payload[:count]).to eq(issuables.count)
    end

    it 'updates the issuables confidentiality' do
      bulk_update(issuables, confidential: true)

      issuables.each do |issuable|
        expect(issuable.reload.confidential).to be(true)
      end
    end
  end

  shared_examples 'updating labels' do
    def create_issue_with_labels(labels)
      create(:labeled_issue, project: project, labels: labels)
    end

    let(:issue_all_labels) { create_issue_with_labels([bug, regression, merge_requests]) }
    let(:issue_bug_and_regression) { create_issue_with_labels([bug, regression]) }
    let(:issue_bug_and_merge_requests) { create_issue_with_labels([bug, merge_requests]) }
    let(:issue_no_labels) { create(:issue, project: project) }
    let(:issues) { [issue_all_labels, issue_bug_and_regression, issue_bug_and_merge_requests, issue_no_labels] }

    let(:add_labels) { [] }
    let(:remove_labels) { [] }

    let(:bulk_update_params) do
      {
        add_label_ids: add_labels.map(&:id),
        remove_label_ids: remove_labels.map(&:id)
      }
    end

    before do
      bulk_update(issues, bulk_update_params)
    end

    context 'when add_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:add_labels) { [bug, regression, merge_requests] }

      it 'adds those label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(*add_labels.map(&:id)))
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end

    context 'when remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:remove_labels) { [bug, regression, merge_requests] }

      it 'removes those label IDs from all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(be_empty)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end

    context 'when add_label_ids and remove_label_ids are passed' do
      let(:issues) { [issue_all_labels, issue_bug_and_merge_requests, issue_no_labels] }
      let(:add_labels) { [bug] }
      let(:remove_labels) { [merge_requests] }

      it 'adds the label IDs to all issues passed' do
        expect(issues.map(&:reload).map(&:label_ids)).to all(include(bug.id))
      end

      it 'removes the label IDs from all issues passed' do
        expect(issues.map(&:reload).flat_map(&:label_ids)).not_to include(merge_requests.id)
      end

      it 'does not update issues not passed in' do
        expect(issue_bug_and_regression.label_ids).to contain_exactly(bug.id, regression.id)
      end
    end
  end

  shared_examples 'scheduling cached group count clear' do
    it 'schedules worker' do
      expect(Issuables::ClearGroupsIssueCounterWorker).to receive(:perform_async)

      bulk_update(issuables, params)
    end
  end

  shared_examples 'not scheduling cached group count clear' do
    it 'does not schedule worker' do
      expect(Issuables::ClearGroupsIssueCounterWorker).not_to receive(:perform_async)

      bulk_update(issuables, params)
    end
  end

  shared_examples 'bulk update service' do
    it 'result count only includes authorized issuables' do
      all_issues = issues + [create(:issue, project: create(:project, :private))]
      result = bulk_update(all_issues, { assignee_ids: [user.id] })

      expect(result[:count]).to eq(issues.count)
    end

    context 'when issuable_ids are passed as an array' do
      it 'updates assignees' do
        expect do
          described_class.new(
            parent,
            user,
            { issuable_ids: issues.map(&:id), assignee_ids: [user.id] }
          ).execute('issue')

          issues.each(&:reset)
        end.to change { issues.flat_map(&:assignee_ids) }.from([]).to([user.id] * 2)
      end
    end
  end

  context 'with issuables at a project level' do
    let_it_be_with_reload(:issues) { create_list(:issue, 2, project: project) }

    let(:parent) { project }

    it_behaves_like 'bulk update service'

    context 'with unpermitted attributes' do
      let(:label) { create(:label, project: project) }

      it 'does not update the issues' do
        bulk_update(issues, label_ids: [label.id])

        expect(issues.map(&:reload).map(&:label_ids)).not_to include(label.id)
      end
    end

    context 'when issuable update service raises an ArgumentError' do
      before do
        allow_next_instance_of(Issues::UpdateService) do |update_service|
          allow(update_service).to receive(:execute).and_raise(ArgumentError, 'update error')
        end
      end

      it 'returns an error response' do
        result = bulk_update(issues, add_label_ids: [])

        expect(result).to be_error
        expect(result.errors).to contain_exactly('update error')
        expect(result.http_status).to eq(422)
      end
    end

    describe 'close issues' do
      it 'succeeds and returns the correct number of issues updated' do
        result = bulk_update(issues, state_event: 'close')

        expect(result.success?).to be_truthy
        expect(result.payload[:count]).to eq(issues.count)
      end

      it 'closes all the issues passed' do
        bulk_update(issues, state_event: 'close')

        expect(project.issues.opened).to be_empty
        expect(project.issues.closed).not_to be_empty
      end

      it_behaves_like 'scheduling cached group count clear' do
        let(:issuables) { issues }
        let(:params) { { state_event: 'close' } }
      end
    end

    describe 'reopen issues' do
      let_it_be_with_reload(:closed_issues) { create_list(:closed_issue, 2, project: project) }

      it 'succeeds and returns the correct number of issues updated' do
        result = bulk_update(closed_issues, state_event: 'reopen')

        expect(result.success?).to be_truthy
        expect(result.payload[:count]).to eq(closed_issues.count)
      end

      it 'reopens all the issues passed' do
        bulk_update(closed_issues, state_event: 'reopen')

        expect(project.issues.closed).to be_empty
        expect(project.issues.opened).not_to be_empty
      end

      it_behaves_like 'scheduling cached group count clear' do
        let(:issuables) { closed_issues }
        let(:params) { { state_event: 'reopen' } }
      end
    end

    describe 'updating merge request assignee' do
      let(:merge_request) { create(:merge_request, target_project: project, source_project: project, assignees: [user]) }

      context 'when the new assignee ID is a valid user' do
        it 'succeeds' do
          new_assignee = create(:user)
          project.add_developer(new_assignee)

          result = bulk_update(merge_request, assignee_ids: [user.id, new_assignee.id])

          expect(result.success?).to be_truthy
          expect(result.payload[:count]).to eq(1)
        end

        it 'updates the assignee to the user ID passed' do
          assignee = create(:user)
          project.add_developer(assignee)

          expect { bulk_update(merge_request, assignee_ids: [assignee.id]) }
            .to change { merge_request.reload.assignee_ids }.from([user.id]).to([assignee.id])
        end
      end

      context "when the new assignee ID is #{IssuableFinder::Params::NONE}" do
        it 'unassigns the issues' do
          expect { bulk_update(merge_request, assignee_ids: [IssuableFinder::Params::NONE]) }
            .to change { merge_request.reload.assignee_ids }.to([])
        end
      end

      context 'when the new assignee IDs array is empty' do
        it 'removes all assignees' do
          expect { bulk_update(merge_request, assignee_ids: []) }
            .to change(merge_request.assignees, :count).by(-1)
        end
      end
    end

    describe 'updating issue assignee' do
      let(:issue) { create(:issue, project: project, assignees: [user]) }

      context 'when the new assignee ID is a valid user' do
        it 'succeeds' do
          new_assignee = create(:user)
          project.add_developer(new_assignee)

          result = bulk_update(issue, assignee_ids: [new_assignee.id])

          expect(result.success?).to be_truthy
          expect(result.payload[:count]).to eq(1)
        end

        it 'updates the assignee to the user ID passed' do
          assignee = create(:user)
          project.add_developer(assignee)
          expect { bulk_update(issue, assignee_ids: [assignee.id]) }
            .to change { issue.reload.assignees.first }.from(user).to(assignee)
        end
      end

      context "when the new assignee ID is #{IssuableFinder::Params::NONE}" do
        it "unassigns the issues" do
          expect { bulk_update(issue, assignee_ids: [IssuableFinder::Params::NONE.to_s]) }
            .to change { issue.reload.assignees.count }.from(1).to(0)
        end
      end

      context 'when the new assignee IDs array is empty' do
        it 'removes all assignees' do
          expect { bulk_update(issue, assignee_ids: []) }
            .to change(issue.assignees, :count).by(-1)
        end
      end
    end

    describe 'updating milestones' do
      let(:issuables) { [create(:issue, project: project)] }
      let(:milestone) { create(:milestone, project: project) }

      it_behaves_like 'updates milestones'

      it_behaves_like 'not scheduling cached group count clear' do
        let(:params) { { milestone_id: milestone.id } }
      end
    end

    describe 'updating confidentiality' do
      let(:issuables) { create_list(:issue, 2, project: project) }

      it_behaves_like 'updates confidentiality'

      it_behaves_like 'not scheduling cached group count clear' do
        let(:params) { { confidential: true } }
      end
    end

    describe 'updating labels' do
      let(:bug) { create(:label, project: project) }
      let(:regression) { create(:label, project: project) }
      let(:merge_requests) { create(:label, project: project) }

      it_behaves_like 'updating labels'
    end

    describe 'subscribe to issues' do
      let(:issues) { create_list(:issue, 2, project: project) }

      it 'subscribes the given user' do
        bulk_update(issues, subscription_event: 'subscribe')

        expect(issues).to all(be_subscribed(user, project))
      end
    end

    describe 'unsubscribe from issues' do
      let(:issues) do
        create_list(:closed_issue, 2, project: project) do |issue|
          issue.subscriptions.create!(user: user, project: project, subscribed: true)
        end
      end

      it 'unsubscribes the given user' do
        bulk_update(issues, subscription_event: 'unsubscribe')

        issues.each do |issue|
          expect(issue).not_to be_subscribed(user, project)
        end
      end
    end

    describe 'updating issues from external project' do
      it 'updates only issues that belong to the parent project' do
        issue1 = create(:issue, project: project)
        issue2 = create(:issue, project: create(:project))
        result = bulk_update([issue1, issue2], assignee_ids: [user.id])

        expect(result.success?).to be_truthy
        expect(result.payload[:count]).to eq(1)

        expect(issue1.reload.assignees).to eq([user])
        expect(issue2.reload.assignees).to be_empty
      end
    end
  end

  context 'with issuables at a group level' do
    let_it_be(:group) { create(:group) }

    let(:parent) { group }

    before do
      group.add_reporter(user)
    end

    it_behaves_like 'bulk update service' do
      let_it_be_with_reload(:issues) { create_list(:issue, 2, project: create(:project, group: group)) }
    end

    describe 'updating milestones' do
      let(:milestone) { create(:milestone, group: group) }
      let(:project)   { create(:project, :repository, group: group) }

      before do
        group.add_maintainer(user)
      end

      context 'when issues' do
        let(:issue1)    { create(:issue, project: project) }
        let(:issue2)    { create(:issue, project: project) }
        let(:issuables) { [issue1, issue2] }

        it_behaves_like 'updates milestones'
      end

      context 'when merge requests' do
        let(:merge_request1) { create(:merge_request, source_project: project, source_branch: 'branch-1') }
        let(:merge_request2) { create(:merge_request, source_project: project, source_branch: 'branch-2') }
        let(:issuables)      { [merge_request1, merge_request2] }

        it_behaves_like 'updates milestones'
      end
    end

    describe 'updating confidentiality' do
      let_it_be(:project) { create(:project, :repository, group: group) }

      before do
        group.add_maintainer(user)
      end

      context 'with issues' do
        let(:issuables) { create_list(:issue, 2, project: project) }

        it_behaves_like 'updates confidentiality'
      end

      context 'with merge requests' do
        let(:issuables) { [create(:merge_request, source_project: project, target_project: project)] }

        it 'does not throw an error' do
          result = bulk_update(issuables, confidential: true)

          expect(result.success?).to be_truthy
        end
      end
    end

    describe 'updating labels' do
      let(:project)        { create(:project, :repository, group: group) }
      let(:bug)            { create(:group_label, group: group) }
      let(:regression)     { create(:group_label, group: group) }
      let(:merge_requests) { create(:group_label, group: group) }

      it_behaves_like 'updating labels'
    end

    describe 'with issues from external group' do
      it 'updates issues that belong to the parent group or descendants' do
        issue1 = create(:issue, project: create(:project, group: group))
        issue2 = create(:issue, project: create(:project, group: create(:group)))
        issue3 = create(:issue, project: create(:project, group: create(:group, parent: group)))
        milestone = create(:milestone, group: group)
        result = bulk_update([issue1, issue2, issue3], milestone_id: milestone.id)

        expect(result.success?).to be_truthy
        expect(result.payload[:count]).to eq(2)

        expect(issue1.reload.milestone).to eq(milestone)
        expect(issue2.reload.milestone).to be_nil
        expect(issue3.reload.milestone).to eq(milestone)
      end
    end
  end

  context 'when no parent is provided' do
    it 'returns an unscoped update error' do
      result = described_class.new(nil, user, { assignee_ids: [user.id], issuable_ids: [] }).execute('issue')

      expect(result).to be_error
      expect(result.errors).to contain_exactly(_('A parent must be provided when bulk updating issuables'))
    end
  end
end
