# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::IssuesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| group.add_reporter(u) } }
  let_it_be(:milestone1) { create(:milestone, group: group) }
  let_it_be(:milestone2) { create(:milestone, group: group) }
  let_it_be(:iteration1) { create(:iteration, group: group) }
  let_it_be(:iteration2) { create(:iteration, group: group) }

  let_it_be(:issue1, reload: true) do
    create(:issue, project: project, assignee_ids: [developer.id], milestone: milestone1, iteration: iteration1)
  end

  let_it_be(:issue2, reload: true) do
    create(:issue, project: project, assignee_ids: [developer.id], milestone: milestone1, iteration: iteration1)
  end

  let(:updatable_issues) { [issue1, issue2] }

  describe 'POST #bulk_update' do
    subject(:post_request) { post bulk_update_group_issues_path(group_id: group.full_path), params: params, as: :json }

    context 'when group bulk edit feature is enabled' do
      let(:assignee_ids) { [reporter.id] }
      let(:milestone_id) { milestone2.id }
      let(:iteration_id) { iteration2.id }
      let(:params) do
        {
          group_id: group.id,
          update: {
            issuable_ids: "#{issue1.id}, #{issue2.id}",
            assignee_ids: assignee_ids,
            milestone_id: milestone_id,
            sprint_id: iteration_id
          }
        }
      end

      before do
        stub_licensed_features(group_bulk_edit: true)
        login_as(developer)
      end

      it 'updates attributes for selected issues' do
        expect do
          post_request

          issue1.reload
          issue2.reload
        end.to change { updatable_issues.flat_map(&:assignee_ids) }.from([developer.id] * 2).to([reporter.id] * 2)
          .and(change { updatable_issues.map(&:milestone_id) }.from([milestone1.id] * 2).to([milestone2.id] * 2))
          .and(change { updatable_issues.map(&:sprint_id) }.from([iteration1.id] * 2).to([iteration2.id] * 2))
      end

      context 'when setting arguments to null or none' do
        let(:assignee_ids) { [] }
        let(:milestone_id) { nil }
        let(:iteration_id) { nil }

        it 'does not unset arguments' do
          expect do
            post_request

            issue1.reload
            issue2.reload
          end.to not_change { updatable_issues.flat_map(&:assignee_ids) }.from([developer.id] * 2)
            .and(not_change { updatable_issues.map(&:milestone_id) }.from([milestone1.id] * 2))
            .and(not_change { updatable_issues.map(&:sprint_id) }.from([iteration1.id] * 2))
        end

        context 'when assignee_ids contains only null elements' do
          let(:assignee_ids) { [nil, nil] }

          it 'does not unset assignees' do
            expect do
              post_request

              issue1.reset
              issue2.reset
            end.to not_change(issue1, :assignee_ids).from([developer.id])
              .and(not_change(issue2, :assignee_ids).from([developer.id]))
          end
        end
      end
    end
  end
end
