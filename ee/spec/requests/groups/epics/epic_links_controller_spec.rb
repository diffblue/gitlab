# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Epics::EpicLinksController do
  let(:group) { create(:group, :public) }
  let(:parent_epic) { create(:epic, group: group) }
  let(:epic1) { create(:epic, group: group) }
  let(:epic2) { create(:epic, group: group) }
  let(:user)  { create(:user) }
  let(:features_when_forbidden) { { epics: true, subepics: false } }

  before do
    sign_in(user)
  end

  shared_examples 'unlicensed subepics action' do
    before do
      stub_licensed_features(features_when_forbidden)
      group.add_developer(user)

      subject
    end

    it 'returns 403 status' do
      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET #index' do
    let(:features_when_forbidden) { { epics: false } }

    before do
      epic1.update!(parent: parent_epic)
    end

    subject { get group_epic_links_path(group_id: group, epic_id: parent_epic.to_param) }

    it_behaves_like 'unlicensed subepics action'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has access to epic' do
        before do
          group.add_developer(user)

          subject
        end

        it 'returns the correct JSON response' do
          list_service_response = Epics::EpicLinks::ListService.new(parent_epic, user).execute

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq(list_service_response.as_json)
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
      reference = [epic1.to_reference(full: true)]

      post group_epic_links_path(group_id: group, epic_id: parent_epic.to_param, issuable_references: reference)
    end

    it_behaves_like 'unlicensed subepics action'

    context 'when subepics are enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user has permissions to create requested association' do
        before do
          group.add_developer(user)
        end

        it 'returns correct response for the correct issue reference' do
          subject
          list_service_response = Epics::EpicLinks::ListService.new(parent_epic, user).execute

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq('message' => nil, 'issuables' => list_service_response.as_json)
        end

        it 'updates a parent for the referenced epic' do
          expect { subject }.to change { epic1.reload.parent }.from(nil).to(parent_epic)
        end
      end

      context 'when user does not have permissions to create requested association' do
        it 'returns 403 status' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not update parent attribute' do
          expect { subject }.not_to change { epic1.reload.parent }.from(nil)
        end
      end
    end
  end

  describe 'PUT #update' do
    before do
      epic1.update!(parent: parent_epic)
      epic2.update!(parent: parent_epic)
    end

    let(:move_before_epic) { epic2 }

    subject do
      put group_epic_link_path(group_id: group, epic_id: parent_epic.to_param,
                               id: epic1.id, epic: { move_before_id:
                                                     move_before_epic.id })
    end

    it_behaves_like 'unlicensed subepics action'

    context 'when subepics are enabled' do
      before do
        stub_licensed_features(epics: true, subepics: true)
      end

      context 'when user has permissions to reorder epics' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates the epic position' do
          expect { subject }.to change { epic1.reload.relative_position }
        end

        context 'when move_before_id is not a sibling epic' do
          let(:move_before_epic) { create(:epic, group: group) }

          it 'returns status 404' do
            subject

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user does not have permissions to reorder epics' do
        it 'returns status 403' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      epic1.update!(parent: parent_epic)
    end

    let(:features_when_forbidden) { { epics: false } }

    subject { delete group_epic_link_path(group_id: group, epic_id: parent_epic.to_param, id: epic1.id) }

    it_behaves_like 'unlicensed subepics action'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to update the parent epic' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'destroys the link' do
          expect { subject }.to change { epic1.reload.parent }.from(parent_epic).to(nil)
        end
      end

      context 'when user does not have permissions to update the parent epic' do
        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'does not destroy the link' do
          expect { subject }.not_to change { epic1.reload.parent }.from(parent_epic)
        end
      end

      context 'when the epic does not have any parent' do
        it 'returns status 404' do
          delete group_epic_link_path(group_id: group, epic_id: parent_epic.to_param, id: epic2.id)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when user has permissions to update the parent epic but epics feature is disabled' do
      before do
        stub_licensed_features(epics: false)
        group.add_developer(user)
      end

      it 'does not destroy the link' do
        expect { subject }.not_to change { epic1.reload.parent }.from(parent_epic)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
