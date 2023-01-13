# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EpicIssuesController, feature_category: :portfolio_management do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, group: group) }
  let(:milestone) { create(:milestone, project: project) }
  let(:epic) { create(:epic, group: group) }
  let(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, milestone: milestone, assignees: [user]) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  shared_examples 'unlicensed epics action' do
    before do
      stub_licensed_features(epics: false)
      group.add_guest(user)

      subject
    end

    it 'returns 403 status' do
      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET #index' do
    let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

    subject { get :index, params: { group_id: group, epic_id: epic.to_param } }

    it_behaves_like 'unlicensed epics action'

    context 'when epics feature is enabled' do
      context 'when user has access to epic' do
        before do
          group.add_guest(user)

          subject
        end

        it 'returns status 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns the correct json' do
          expect(json_response).to match_schema('related_issues', dir: 'ee')
        end
      end

      context 'when user does not have access to epic' do
        it 'returns 404 status' do
          group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'POST #create' do
    subject do
      reference = [issue.to_reference(full: true)]

      post :create, params: { group_id: group, epic_id: epic.to_param, issuable_references: reference }
    end

    it_behaves_like 'unlicensed epics action'

    context 'when epics feature is enabled' do
      context 'when user has permissions to create requested association' do
        before do
          group.add_guest(user)
        end

        it 'returns correct response for the correct issue reference' do
          subject
          list_service_response = EpicIssues::ListService.new(epic, user).execute

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('message' => nil, 'issuables' => list_service_response.as_json)
        end

        it 'creates a new EpicIssue record' do
          expect { subject }.to change { EpicIssue.count }.from(0).to(1)
        end
      end

      context 'when user does not have permissions to create requested association' do
        it 'returns correct response for the correct issue reference' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not create a new EpicIssue record' do
          expect { subject }.not_to change { EpicIssue.count }.from(0)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

    subject { delete :destroy, params: { group_id: group, epic_id: epic.to_param, id: epic_issue.id } }

    it_behaves_like 'unlicensed epics action'

    context 'when epics feature is enabled' do
      context 'when user has permissions to delete the link' do
        before do
          group.add_guest(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'destroys the link' do
          expect { subject }.to change { EpicIssue.count }.from(1).to(0)
        end
      end

      context 'when user does not have permissions to delete the link' do
        it 'returns status 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end
      end

      context 'when the epic from the association does not equal epic from the path' do
        subject do
          delete :destroy, params: { group_id: group, epic_id: another_epic.to_param, id: epic_issue.id }
        end

        let(:another_epic) { create(:epic, group: group) }

        before do
          group.add_guest(user)
        end

        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end
      end

      context 'when the epic_issue record does not exists' do
        it 'returns status 404' do
          group.add_guest(user)

          delete :destroy, params: { group_id: group, epic_id: epic.to_param, id: 0 }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:issue2) { create(:issue, project: project) }
    let!(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue, relative_position: 1) }
    let!(:epic_issue2) { create(:epic_issue, epic: epic, issue: issue2, relative_position: 2) }

    subject do
      put :update, params: { group_id: group, epic_id: epic.to_param, id: epic_issue1.id, epic: { move_before_id: epic_issue2.id } }
    end

    it_behaves_like 'unlicensed epics action'

    context 'when epics feature is enabled' do
      context 'when user has permissions to admin the epic' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates the issue position value' do
          expect { subject }.to change { epic_issue1.reload.relative_position }
        end
      end

      context 'when user does not have permissions to admin the epic' do
        it 'returns status 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when the epic from the association does not equal epic from the path' do
        subject do
          put :update, params: { group_id: group, epic_id: another_epic.to_param, id: epic_issue1.id, epic: { after_move_id: epic_issue1.id } }
        end

        let(:another_epic) { create(:epic, group: group) }

        before do
          group.add_developer(user)
        end

        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the epic_issue record does not exists' do
        it 'returns status 404' do
          group.add_developer(user)

          delete :destroy, params: { group_id: group, epic_id: epic.to_param, id: non_existing_record_id }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
