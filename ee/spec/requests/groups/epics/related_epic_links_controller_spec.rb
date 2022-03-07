# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Epics::RelatedEpicLinksController do
  let_it_be(:user) { create(:user) }
  let_it_be(:epic) { create(:epic) }
  let_it_be(:epic_link1) { create(:related_epic_link, source: epic) }
  let_it_be(:epic_link2) { create(:related_epic_link, source: epic) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
  end

  describe 'GET /*group_id/:group_id/epics/:epic_id/related_epic_links' do
    subject(:request) do
      get group_epic_related_epic_links_path(group_id: epic.group, epic_id: epic.iid, format: :json)
    end

    before do
      epic.group.add_guest(user)
      login_as user
    end

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
end
