# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RelatedEpicLinks do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:epic) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
  end

  shared_examples 'a not available endpoint' do
    subject { perform_request(user) }

    context 'when epics feature is not available' do
      before do
        stub_licensed_features(epics: false, related_epics: true)
      end

      it { is_expected.to eq(403) }
    end

    context 'when related_epics feature is not available ' do
      before do
        stub_licensed_features(epics: true, related_epics: false)
      end

      it { is_expected.to eq(403) }
    end

    context 'when related epics widget feature flag is disabled' do
      before do
        stub_licensed_features(epics: true, related_epics: true)
        stub_feature_flags(related_epics_widget: false)
      end

      it { is_expected.to eq(404) }
    end
  end

  describe 'GET /related_epics' do
    def perform_request(user = nil, params = {})
      get api("/groups/#{group.id}/epics/#{epic.iid}/related_epics", user), params: params
    end

    context 'when user cannot read epics' do
      it 'returns 404' do
        perform_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user can read epics' do
      let_it_be(:group_2) { create(:group) }
      let_it_be(:related_epic_link_1) { create(:related_epic_link, source: epic, target: create(:epic, group: group)) }
      let_it_be(:related_epic_link_2) { create(:related_epic_link, source: epic, target: create(:epic, group: group_2)) }

      before do
        group.add_guest(user)
      end

      it_behaves_like 'a not available endpoint'

      it 'returns related epics' do
        perform_request(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(response).to match_response_schema('public_api/v4/related_epic_links', dir: 'ee')
      end

      it 'returns multiple links without N + 1' do
        perform_request(user)

        control_count = ActiveRecord::QueryRecorder.new { perform_request(user) }.count

        create(:related_epic_link, source: epic, target: create(:epic, group: group))

        expect { perform_request(user) }.not_to exceed_query_limit(control_count)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
