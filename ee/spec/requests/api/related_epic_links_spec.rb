# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::RelatedEpicLinks, feature_category: :portfolio_management do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:epic) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
  end

  shared_examples 'forbidden resource' do |message|
    it 'returns 403' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'not found resource' do |message|
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq(message)
    end
  end

  shared_examples 'unauthenticated resource' do
    it 'returns 401' do
      perform_request

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'successful response' do |status|
    it "returns #{status}" do
      subject

      expect_link_response(status: status)
    end
  end

  shared_examples 'endpoint with features check' do
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
  end

  shared_examples 'insufficient permissions' do
    context 'when user can not access source epic' do
      before do
        target_group.add_guest(user)
      end

      it_behaves_like 'not found resource', '404 Group Not Found'
    end

    context 'when user can only read source epic' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:public_epic) { create(:epic, group: public_group) }

      before do
        target_group.add_guest(user)
      end

      it_behaves_like 'forbidden resource' do
        let(:group) { public_group }
        let(:epic) { public_epic }
      end
    end
  end

  describe 'GET /related_epics' do
    def perform_request(user = nil, params = {})
      get api("/groups/#{group.id}/epics/#{epic.iid}/related_epics", user), params: params
    end

    subject { perform_request(user) }

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

      it_behaves_like 'endpoint with features check'

      it 'returns related epics' do
        perform_request(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(response).to match_response_schema('public_api/v4/related_epics', dir: 'ee')
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

  describe 'POST /related_epics' do
    let_it_be(:target_group) { create(:group, :private) }
    let_it_be(:target_epic) { create(:epic, group: target_group) }

    let(:target_epic_iid) { target_epic.iid }

    subject { perform_request(user, target_group_id: target_group.id, target_epic_iid: target_epic_iid) }

    def perform_request(user = nil, params = {})
      post api("/groups/#{group.id}/epics/#{epic.iid}/related_epics", user), params: params
    end

    it_behaves_like 'unauthenticated resource'
    it_behaves_like 'insufficient permissions'

    context 'when user can only manage source epic' do
      before do
        group.add_guest(user)
      end

      it_behaves_like 'not found resource', '404 Group Not Found'

      context 'when user is guest in target group' do
        before do
          target_group.add_guest(user)
        end

        it_behaves_like 'successful response', :created

        context 'when target epic is confidential' do
          let_it_be(:confidential_target_epic) { create(:epic, :confidential, group: target_group) }

          let(:target_epic_iid) { confidential_target_epic.iid }

          it_behaves_like 'forbidden resource'
        end
      end

      context 'when user can relate epics' do
        before do
          target_group.add_guest(user)
        end

        it_behaves_like 'endpoint with features check'

        it_behaves_like 'successful response', :created

        it 'returns 201 when sending full path of target group' do
          perform_request(user, target_group_id: target_group.full_path, target_epic_iid: target_epic.iid, link_type: 'blocks')

          expect_link_response(link_type: 'blocks')
        end

        context 'when target epic is not found' do
          let(:target_epic_iid) { non_existing_record_iid }

          it_behaves_like 'not found resource', '404 Not found'
        end
      end
    end
  end

  describe 'DELETE /related_epics' do
    let_it_be(:target_group) { create(:group, :private) }
    let_it_be(:target_epic) { create(:epic, group: target_group) }
    let_it_be_with_reload(:related_epic_link) { create(:related_epic_link, source: epic, target: target_epic) }

    subject { perform_request(user) }

    def perform_request(user = nil)
      delete api("/groups/#{group.id}/epics/#{epic.iid}/related_epics/#{related_epic_link.id}", user)
    end

    it_behaves_like 'unauthenticated resource'
    it_behaves_like 'insufficient permissions'

    context 'when user can manage source epic' do
      before do
        group.add_guest(user)
      end

      it_behaves_like 'not found resource', 'No Related Epic Link found'

      context 'when user is guest in target group' do
        before do
          target_group.add_guest(user)
        end

        it_behaves_like 'successful response', :ok
      end

      context 'when related_epic_link_id belongs to a different epic' do
        let_it_be(:other_epic) { create(:epic, group: target_group) }
        let_it_be(:other_epic_link) { create(:related_epic_link, source: other_epic, target: target_epic) }

        subject { delete api("/groups/#{group.id}/epics/#{epic.iid}/related_epics/#{other_epic_link.id}", user) }

        before do
          target_group.add_guest(user)
        end

        it_behaves_like 'not found resource', '404 Not found'
      end

      context 'when user can relate epics' do
        before do
          target_group.add_guest(user)
        end

        it_behaves_like 'endpoint with features check'
        it_behaves_like 'successful response', :ok
      end
    end
  end

  def expect_link_response(link_type: 'relates_to', status: :created)
    expect(response).to have_gitlab_http_status(status)
    expect(response).to match_response_schema('public_api/v4/related_epic_link')
    expect(json_response['link_type']).to eq(link_type)
  end
end
