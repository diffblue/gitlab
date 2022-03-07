# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Epics::RelatedEpicLinksController do
  let_it_be(:user) { create(:user) }
  let_it_be(:epic) { create(:epic) }
  let_it_be(:epic2) { create(:epic, group: epic.group) }
  let_it_be(:epic_link1) { create(:related_epic_link, source: epic, target: epic2) }
  let_it_be(:epic_link2) { create(:related_epic_link, source: epic) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
  end

  shared_examples 'a not available action' do
    context 'when related_epics flag is disabled' do
      before do
        stub_feature_flags(related_epics_widget: false)
      end

      it 'returns not_found error' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when related_epics are not available' do
      before do
        stub_licensed_features(epics: true, related_epics: false)
      end

      it 'returns not_found error' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /*group_id/:group_id/epics/:epic_id/related_epic_links' do
    subject(:request) do
      get group_epic_related_epic_links_path(group_id: epic.group, epic_id: epic.iid, format: :json)
    end

    before do
      epic.group.add_guest(user)
      login_as user
    end

    it_behaves_like 'a not available action'

    it 'returns JSON response' do
      list_service_response = Epics::RelatedEpicLinks::ListService.new(epic, user).execute

      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(list_service_response.as_json)
    end

    it 'avoids N+1 queries' do
      def do_request
        get group_epic_related_epic_links_path(group_id: epic.group, epic_id: epic.iid, format: :json)
      end

      do_request # warm up

      control = ActiveRecord::QueryRecorder.new { do_request }

      create(:related_epic_link, source: epic)

      expect { do_request }.not_to exceed_query_limit(control)
    end
  end

  describe 'DELETE /*group_id/:group_id/epics/:epic_id/related_epic_links/:link_id' do
    subject(:request) do
      delete group_epic_related_epic_link_path(id: epic_link1.id, group_id: epic.group, epic_id: epic.iid, format: :json)
    end

    before do
      epic.group.add_reporter(user)
      login_as user
    end

    it_behaves_like 'a not available action'

    it 'deletes related epic link' do
      expect { request }.to change(Epic::RelatedEpicLink, :count).by(-1)
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when related epic link id is not valid' do
      it 'returns 404' do
        delete group_epic_related_epic_link_path(id: 999, group_id: epic.group, epic_id: epic.iid, format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when related epic link does not belong to epic' do
      let!(:link) { create(:related_epic_link) }

      subject(:request) do
        delete group_epic_related_epic_link_path(id: link.id, group_id: epic.group, epic_id: epic.iid, format: :json)
      end

      it 'does not delete related epic link' do
        expect { request }.not_to change(Epic::RelatedEpicLink, :count)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
