# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Epics::RelatedEpicLinksController, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:epic, reload: true) { create(:epic) }
  let_it_be(:epic2) { create(:epic, group: epic.group) }
  let_it_be(:epic3) { create(:epic, group: epic.group) }
  let_it_be(:epic_link1) { create(:related_epic_link, source: epic, target: epic3) }
  let_it_be(:epic_link2) { create(:related_epic_link, source: epic) }
  let_it_be(:listing_service) { Epics::RelatedEpicLinks::ListService }

  before do
    stub_licensed_features(epics: true, related_epics: true)
  end

  shared_examples 'a not available action' do
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

      create(:related_epic_link, source: epic, target: epic2)

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

  describe 'POST /groups/*group_id/-/epics/:epic_id/related_epic_links' do
    let(:issuable_references) { [epic2.to_reference(full: true)] }

    subject(:request) do
      post group_epic_related_epic_links_path(related_epics_params(issuable_references: issuable_references))
    end

    before do
      epic.group.add_guest(user)
      epic2.group.add_guest(user)
      login_as user
    end

    context 'with success' do
      it 'returns JSON response' do
        request

        list_service_response = listing_service.new(epic, user).execute
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('message' => nil,
                                    'issuables' => list_service_response.as_json)
      end

      it 'delegates the creation of the related epic link to Epics::RelatedEpicLinks::CreateService' do
        expect_next_instance_of(Epics::RelatedEpicLinks::CreateService) do |service|
          expect(service).to receive(:execute).once.and_call_original
        end

        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'creates a new Epic::RelatedEpicLink record' do
        expect { request }.to change { Epic::RelatedEpicLink.count }.by(1)
      end

      it 'returns correct relation path in response' do
        request
        related_epic_link = Epic::RelatedEpicLink.find_by(source: epic, target: epic2)

        expect(json_response['issuables'].last)
          .to include('relation_path' => "/groups/#{epic.group.path}/-/epics/#{epic.iid}/related_epic_links/#{related_epic_link&.id}")
      end
    end

    context 'with failure' do
      context 'when unauthorized' do
        before do
          epic.update!(confidential: true)
        end

        it 'returns 403' do
          epic.group.add_guest(user)

          request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when failing service result' do
        let(:issuable_references) { ["##{non_existing_record_iid}"] }

        it 'returns failure JSON' do
          request

          list_service_response = listing_service.new(epic, user).execute

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response).to eq('message' => 'No matching epic found. Make sure that you are adding a valid epic URL.', 'issuables' => list_service_response.as_json)
        end
      end

      it_behaves_like 'a not available action'
    end
  end

  def related_epics_params(opts = {})
    opts.reverse_merge(group_id: epic.group,
                       epic_id: epic.iid,
                       format: :json)
  end
end
