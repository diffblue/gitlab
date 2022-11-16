# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::IssuesController, feature_category: :team_planning do
  let(:group)     { create(:group, :public) }
  let(:project)   { create(:project_empty_repo, :public, namespace: group) }
  let(:milestone) { create(:milestone, group: group) }
  let(:user)      { create(:user) }
  let(:epic)      { create(:epic, group: group) }
  let(:issue1)    { create(:issue, project: project) }
  let(:issue2)    { create(:issue, project: project) }

  describe 'POST #bulk_update' do
    subject { post :bulk_update, params: params, format: :json }

    let(:params) do
      {
        update: {
          milestone_id: milestone.id,
          issuable_ids: "#{issue1.id}, #{issue2.id}",
          epic_id: epic.id
          },
        group_id: group
        }
    end

    context 'when group bulk edit feature is not enabled' do
      before do
        stub_licensed_features(epics: true, group_bulk_edit: false)
        sign_in(user)
      end

      it 'returns 404 status' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when group bulk edit feature is enabled' do
      before do
        stub_licensed_features(epics: true, group_bulk_edit: true)
        sign_in(user)
      end

      context 'when user has permissions to bulk update issues' do
        before do
          group.add_reporter(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates issues milestone and epic' do
          expect { subject }
            .to change { issue1.reload.milestone }.from(nil).to(milestone)
            .and change { issue2.reload.milestone }.from(nil).to(milestone)
            .and change { issue1.epic }.from(nil).to(epic)
            .and change { issue2.epic }.from(nil).to(epic)
        end

        context 'when params are incorrect' do
          let(:external_epic) { create(:epic, group: create(:group, :private)) }
          let(:params) do
            {
              update: { issuable_ids: "#{issue1.id}, #{issue2.id}", epic_id: external_epic.id },
              group_id: group
            }
          end

          it 'returns 422 status' do
            subject

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(response.body).to include('Epic not found for given params')
          end
        end
      end

      context 'when user does not have permissions to bulk update issues' do
        before do
          group.add_guest(user)
        end

        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not update issues milestone or epic' do
          expect { subject }
            .to not_change { issue1.reload.milestone }
            .and not_change { issue2.reload.milestone }
            .and not_change { issue1.epic }
            .and not_change { issue2.epic }
        end
      end
    end
  end
end
