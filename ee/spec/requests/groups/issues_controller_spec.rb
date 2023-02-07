# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::IssuesController, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| group.add_reporter(u) } }
  let_it_be(:issue1, reload: true) { create(:issue, project: project, assignee_ids: [developer.id]) }
  let_it_be(:issue2, reload: true) { create(:issue, project: project, assignee_ids: [developer.id]) }

  describe 'POST #bulk_update' do
    subject(:post_request) { post bulk_update_group_issues_path(group_id: group.full_path), params: params, as: :json }

    context 'when group bulk edit feature is enabled' do
      before do
        stub_licensed_features(group_bulk_edit: true)
        login_as(developer)
      end

      context 'when updating assignees' do
        let(:assignee_ids) { [reporter.id] }
        let(:params) do
          {
            group_id: group.id,
            update: {
              issuable_ids: "#{issue1.id}, #{issue2.id}",
              assignee_ids: assignee_ids
            }
          }
        end

        it 'updates assignees for selected issues' do
          expect do
            post_request

            issue1.reset
            issue2.reset
          end.to change { issue1.assignee_ids }.from([developer.id]).to([reporter.id])
            .and(change { issue2.assignee_ids }.from([developer.id]).to([reporter.id]))
        end

        context 'when assignee_ids contains an empty array' do
          let(:assignee_ids) { [] }

          it 'does not unset assignees' do
            expect do
              post_request

              issue1.reset
              issue2.reset
            end.to not_change(issue1, :assignee_ids).from([developer.id])
              .and(not_change(issue2, :assignee_ids).from([developer.id]))
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
end
