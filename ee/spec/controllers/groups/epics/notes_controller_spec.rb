# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Epics::NotesController, feature_category: :portfolio_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:epic) { create(:epic, group: group) }
  let(:note) { create(:note, noteable: epic) }
  let(:parsed_response) { json_response.with_indifferent_access }

  before do
    stub_licensed_features(epics: true)
  end

  describe 'GET index' do
    let(:request_params) do
      {
        group_id: group,
        epic_id: epic.iid,
        format: 'json'
      }
    end

    let(:note_json) { parsed_response[:notes].first }

    before do
      group.add_developer(user)
      sign_in(user)
      note
    end

    it 'responds with array of notes' do
      get :index, params: request_params

      expect(parsed_response[:notes]).to be_an Array
      expect(parsed_response[:notes].count).to eq(1)
    end

    context 'with cross-reference system note that is not visible to the current user', :request_store do
      it "does not return any note" do
        expect_next_found_instance_of(Note) do |instance|
          expect(instance).to receive(:readable_by?).and_return(false)
        end

        get :index, params: request_params

        expect(parsed_response[:notes].count).to eq(0)
      end
    end
  end

  describe 'POST create' do
    let(:request_params) do
      {
        note: { note: 'some note', noteable_id: epic.id, noteable_type: 'Epic' },
        group_id: group,
        epic_id: epic.iid,
        format: 'json'
      }
    end

    before do
      sign_in(user)
      group.add_developer(user)
    end

    it "returns status 302 for html" do
      post :create, params: request_params.merge(format: :html)

      expect(response).to have_gitlab_http_status(:found)
    end

    it "returns status 200 for json" do
      post :create, params: request_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(parsed_response[:id]).not_to be_nil
    end

    context "when epic was promoted from issue" do
      let(:project) { create(:project, group: group) }
      let(:issue) { create(:issue, project: project) }
      let!(:discussion) { create(:discussion_note_on_issue, noteable: issue, project: issue.project) }

      let(:epic) { Epics::IssuePromoteService.new(container: project, current_user: user).execute(issue) }
      let(:request_params) do
        {
          note: { note: 'reply note', noteable_id: epic.id, noteable_type: 'Epic' },
          group_id: epic.group,
          epic_id: epic.iid,
          in_reply_to_discussion_id: epic.discussions.first.id,
          format: 'json'
        }
      end

      it "creates reply note for discussion" do
        post :create, params: request_params

        expect(response).to have_gitlab_http_status(:ok)
        expect(parsed_response[:errors]).to be_nil
      end
    end

    it_behaves_like 'create notes request exceeding rate limit', :clean_gitlab_redis_cache do
      let(:current_user) { user }

      def request
        post :create, params: request_params.except(:format)
      end
    end
  end

  describe 'PUT update' do
    let(:request_params) do
      {
        note: { note: 'updated note', noteable_id: epic.id, noteable_type: 'Epic' },
        group_id: group,
        epic_id: epic.iid,
        id: note.id,
        format: 'json'
      }
    end

    before do
      sign_in(note.author)
    end

    it "updates the note" do
      expect { put :update, params: request_params }.to change { note.reload.note }
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
        group_id: group,
        epic_id: epic.iid,
        id: note.id,
        format: 'js'
      }
    end

    before do
      group.add_developer(user)
    end

    context 'user is the author of a note' do
      before do
        sign_in(note.author)
      end

      it "returns status 200" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it "deletes the note" do
        expect { delete :destroy, params: request_params }.to change { Note.count }.from(1).to(0)
      end
    end

    context 'user is not the author of the note' do
      before do
        sign_in(user)
      end

      it "returns status 404" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    let(:request_params) do
      {
        group_id: group,
        epic_id: epic,
        id: note.id
      }
    end

    before do
      group.add_developer(user)
      sign_in(user)
    end

    it "toggles the award emoji" do
      expect do
        post(:toggle_award_emoji, params: request_params.merge(name: "thumbsup"))
      end.to change { note.award_emoji.count }.by(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "removes the already awarded emoji" do
      post(:toggle_award_emoji, params: request_params.merge(name: "thumbsup"))

      expect do
        post(:toggle_award_emoji, params: request_params.merge(name: "thumbsup"))
      end.to change { AwardEmoji.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
