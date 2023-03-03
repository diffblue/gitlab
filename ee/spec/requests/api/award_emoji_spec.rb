# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AwardEmoji, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic) { create(:epic, group: group, author: user) }
  let_it_be(:award_emoji) { create(:award_emoji, awardable: epic, user: user) }
  let_it_be(:note) { create(:note, noteable: epic) }

  before do
    stub_licensed_features(epics: true)

    group.add_developer(user)
  end

  describe "GET /groups/:id/awardable/:awardable_id/award_emoji" do
    context 'on an epic' do
      it "returns an array of award_emoji" do
        get api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.first['name']).to eq(award_emoji.name)
      end

      it "returns a 404 error when epic id not found" do
        get api("/groups/#{group.id}/epics/#{non_existing_record_iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /groups/:id/awardable/:awardable_id/notes/:note_id/award_emoji' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket') }

    it 'returns an array of award emoji' do
      get api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).to eq(rocket.name)
    end
  end

  describe "GET /groups/:id/awardable/:awardable_id/award_emoji/:award_id" do
    context 'on an epic' do
      it "returns the award emoji" do
        get api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji/#{award_emoji.id}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq(award_emoji.name)
        expect(json_response['awardable_id']).to eq(epic.id)
        expect(json_response['awardable_type']).to eq("Epic")
      end

      it "returns a 404 error if the award is not found" do
        get api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /groups/:id/awardable/:awardable_id/notes/:note_id/award_emoji/:award_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket') }

    it 'returns an award emoji' do
      get api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_an Array
      expect(json_response['name']).to eq(rocket.name)
    end
  end

  describe "POST /groups/:id/awardable/:awardable_id/award_emoji" do
    context "on an epic" do
      it "creates a new award emoji" do
        post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user), params: { name: 'blowfish' }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq('blowfish')
        expect(json_response['user']['username']).to eq(user.username)
      end

      it "returns a 400 bad request error if the name is not given" do
        post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it "returns a 404 if the user is not authenticated" do
        post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji"), params: { name: 'thumbsup' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "normalizes +1 as thumbsup award" do
        post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user), params: { name: '+1' }

        expect(epic.award_emoji.last.name).to eq("thumbsup")
      end

      context 'when the emoji already has been awarded' do
        it 'returns a 404 status code' do
          post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user), params: { name: 'thumbsup' }
          post api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji", user), params: { name: 'thumbsup' }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["message"]).to match("has already been taken")
        end
      end
    end
  end

  describe "POST /groups/:id/awardable/:awardable_id/notes/:note_id/award_emoji" do
    let(:note2)  { create(:note, noteable: epic, author: user) }

    it 'creates a new award emoji' do
      expect do
        post api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }
      end.to change { note.award_emoji.count }.from(0).to(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['user']['username']).to eq(user.username)
    end

    it 'marks Todos on the Noteable as done' do
      todo = create(:todo, target: note2.noteable, group: group, user: user)

      post api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }

      expect(todo.reload).to be_done
    end

    it "normalizes +1 as thumbsup award" do
      post api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user), params: { name: '+1' }

      expect(note.award_emoji.last.name).to eq("thumbsup")
    end

    context 'when the emoji already has been awarded' do
      it 'returns a 404 status code' do
        post api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }
        post api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji", user), params: { name: 'rocket' }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response["message"]).to match("has already been taken")
      end
    end
  end

  describe 'DELETE /groups/:id/awardable/:awardable_id/award_emoji/:award_id' do
    context 'when the awardable is an Epic' do
      it 'deletes the award' do
        expect do
          delete api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji/#{award_emoji.id}", user)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { epic.award_emoji.count }.from(1).to(0)
      end

      it 'returns a 404 error when the award emoji can not be found' do
        delete api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it_behaves_like '412 response' do
        let(:request) { api("/groups/#{group.id}/epics/#{epic.iid}/award_emoji/#{award_emoji.id}", user) }
      end
    end
  end

  describe 'DELETE /groups/:id/awardable/:awardable_id/award_emoji/:award_emoji_id' do
    let!(:rocket)  { create(:award_emoji, awardable: note, name: 'rocket', user: user) }

    it 'deletes the award' do
      expect do
        delete api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { note.award_emoji.count }.from(1).to(0)
    end

    it_behaves_like '412 response' do
      let(:request) { api("/groups/#{group.id}/epics/#{epic.iid}/notes/#{note.id}/award_emoji/#{rocket.id}", user) }
    end
  end
end
