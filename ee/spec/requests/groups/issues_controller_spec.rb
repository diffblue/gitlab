# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Groups::IssuesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| group.add_reporter(u) } }
  let_it_be(:milestone1) { create(:milestone, group: group) }
  let_it_be(:milestone2) { create(:milestone, group: group) }
  let_it_be(:iteration1) { create(:iteration, group: group) }
  let_it_be(:iteration2) { create(:iteration, group: group) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:label1) { create(:group_label, group: group) }
  let_it_be(:label2) { create(:group_label, group: group) }
  let_it_be(:health_status1) { Issue.health_statuses.keys[0] }
  let_it_be(:health_status2) { Issue.health_statuses.keys[1] }

  let_it_be(:issue1, reload: true) do
    create(
      :issue,
      project: project,
      assignee_ids: [developer.id],
      milestone: milestone1,
      iteration: iteration1,
      epic: epic1,
      labels: [label1],
      health_status: health_status1
    )
  end

  let_it_be(:issue2, reload: true) do
    create(
      :issue,
      project: project,
      assignee_ids: [developer.id],
      milestone: milestone1,
      iteration: iteration1,
      epic: epic1,
      labels: [label1],
      health_status: health_status1
    )
  end

  let(:updatable_issues) { [issue1, issue2] }

  before_all do
    [issue1, issue2].each { |i| i.subscribe(developer, project) }
  end

  describe 'POST #bulk_update' do
    subject(:post_request) { post bulk_update_group_issues_path(group_id: group.full_path), params: params, as: :json }

    let(:assignee_ids) { [reporter.id] }
    let(:milestone_id) { milestone2.id }
    let(:iteration_id) { iteration2.id }
    let(:state_event) { 'close' }
    let(:subscription_event) { 'unsubscribe' }
    let(:epic_id) { epic2.id }
    let(:add_label_ids) { [label2.id] }
    let(:remove_label_ids) { [label1.id] }
    let(:health_status_name) { health_status2 }
    let(:params) do
      {
        group_id: group.id,
        update: {
          issuable_ids: "#{issue1.id}, #{issue2.id}",
          assignee_ids: assignee_ids,
          milestone_id: milestone_id,
          sprint_id: iteration_id,
          state_event: state_event,
          epic_id: epic_id,
          add_label_ids: add_label_ids,
          remove_label_ids: remove_label_ids,
          health_status: health_status_name,
          subscription_event: subscription_event
        }
      }
    end

    before do
      login_as(developer)
    end

    context 'when group bulk edit feature is not available' do
      before do
        stub_licensed_features(group_bulk_edit: false)
      end

      it 'returns a 404 status' do
        post_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when group bulk edit feature is enabled' do
      before do
        stub_licensed_features(group_bulk_edit: true, epics: true, issuable_health_status: true)
      end

      it 'updates attributes for selected issues' do
        expect do
          post_request

          updatable_issues.each(&:reload)
        end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([developer.id] * 2).to([reporter.id] * 2)
          .and(change { updatable_issues.map(&:milestone_id) }.from([milestone1.id] * 2).to([milestone2.id] * 2))
          .and(change { updatable_issues.map(&:sprint_id) }.from([iteration1.id] * 2).to([iteration2.id] * 2))
          .and(change { updatable_issues.map(&:state) }.from(['opened'] * 2).to(['closed'] * 2))
          .and(change { updatable_issues.map { |i| i.epic.id } }.from([epic1.id] * 2).to([epic2.id] * 2))
          .and(change { updatable_issues.flat_map(&:label_ids) }.from([label1.id] * 2).to([label2.id] * 2))
          .and(change { updatable_issues.map(&:health_status) }.from([health_status1] * 2).to([health_status2] * 2))
          .and(
            change { updatable_issues.map { |i| i.subscribed?(developer, project) } }.from([true] * 2).to([false] * 2)
          )
      end

      context 'when setting arguments to null or none' do
        let(:assignee_ids) { [] }
        let(:milestone_id) { nil }
        let(:iteration_id) { nil }
        let(:state_event) { nil }
        let(:epic_id) { nil }
        let(:add_label_ids) { [] }
        let(:remove_label_ids) { [] }
        let(:health_status_name) { nil }
        let(:subscription_event) { nil }

        it 'does not unset arguments' do
          expect do
            post_request

            updatable_issues.each(&:reset)
          end.to not_change { updatable_issues.flat_map(&:assignee_ids) }.from([developer.id] * 2)
            .and(not_change { updatable_issues.map(&:milestone_id) }.from([milestone1.id] * 2))
            .and(not_change { updatable_issues.map(&:sprint_id) }.from([iteration1.id] * 2))
            .and(not_change { updatable_issues.map(&:state) }.from(['opened'] * 2))
            .and(not_change { updatable_issues.map { |i| i.epic.id } }.from([epic1.id] * 2))
            .and(not_change { updatable_issues.flat_map(&:label_ids) }.from([label1.id] * 2))
            .and(not_change { updatable_issues.map(&:health_status) }.from([health_status1] * 2))
            .and(
              not_change { updatable_issues.map { |i| i.subscribed?(developer, project) } }.from([true] * 2)
            )
        end

        context 'when assignee_ids contains only null elements' do
          let(:assignee_ids) { [nil, nil] }

          it 'does not unset assignees' do
            expect do
              post_request

              updatable_issues.each(&:reset)
            end.to not_change(issue1, :assignee_ids).from([developer.id])
              .and(not_change(issue2, :assignee_ids).from([developer.id]))
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
