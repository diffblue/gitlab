# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::EpicBoards, feature_category: :portfolio_management do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let_it_be(:group, reload: true) { create(:group, :private) }
  let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
  let_it_be(:testing) { create(:group_label, group: group, name: 'Testing') }
  let_it_be(:feature) { create(:group_label, group: group, name: 'Feature') }

  let_it_be(:board1) { create(:epic_board, group: group) }
  let_it_be(:board2) { create(:epic_board, group: group, labels: [development]) }
  let_it_be(:board3) { create(:epic_board, group: group) }
  let_it_be(:board4) { create(:epic_board) }

  let_it_be(:backlog_list) { create(:epic_list, epic_board: board1, label: nil, list_type: :backlog) }
  let_it_be(:closed_list) { create(:epic_list, epic_board: board1, label: nil, list_type: :closed) }

  let_it_be(:list1) { create(:epic_list, epic_board: board1, label: development, position: 0) }
  let_it_be(:list2) { create(:epic_list, epic_board: board1, label: testing, position: 1) }
  let_it_be(:list3) { create(:epic_list, epic_board: board1, label: feature, position: 2) }
  let_it_be(:list4) { create(:epic_list, epic_board: board4) }

  let(:params) { nil }

  before do
    group.add_guest(guest)
  end

  shared_examples 'request with epics unavailable' do
    it 'returns 403 forbidden error' do
      get api(url, guest)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'request with errors' do
    context 'with unauthenticated user' do
      let(:user) { nil }

      it 'returns 401 unauthorized error' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with user without permissions' do
      let(:user) { non_member }

      it 'returns 404 not found error' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when provided ids are not found' do
      let(:user) { guest }
      let(:url) { invalid_url }

      it 'returns 404 not found error' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'request with pagination' do
    let(:user) { guest }
    let(:page) { 1 }
    let(:per_page) { 2 }

    shared_examples 'paginated API endpoint' do
      it 'returns the correct page' do
        get api(url, user), params: { page: page, per_page: per_page }

        expect(response.headers['X-Page']).to eq(page.to_s)
        expect_paginated_array_response(expected)
      end
    end

    context 'when viewing the first page' do
      let(:expected) { [items[0].id, items[1].id] }
      let(:page) { 1 }

      it_behaves_like 'paginated API endpoint'
    end

    context 'when viewing the second page' do
      let(:expected) { [items[2].id] }
      let(:page) { 2 }

      it_behaves_like 'paginated API endpoint'
    end
  end

  describe 'GET /groups/:id/epic_boards' do
    let(:url) { "/groups/#{group.id}/epic_boards" }

    it_behaves_like 'request with epics unavailable'

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it_behaves_like 'request with errors' do
        let(:invalid_url) { "/groups/#{non_existing_record_id}/epic_boards" }
      end

      it_behaves_like 'request with pagination' do
        let(:items) { [board1, board2, board3] }
      end

      context 'when the request is correct' do
        let(:user) { guest }

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
        end

        it 'returns correct information' do
          expect(json_response.pluck('id')).to match_array([board1.id, board2.id, board3.id])
          expect(json_response[0]['lists'].pluck('id'))
            .to match_array([backlog_list.id, closed_list.id, list1.id, list2.id, list3.id])

          expect(json_response[0]['lists'].pluck('label').compact.pluck('id'))
            .to match_array([development.id, testing.id, feature.id])

          expect(json_response[1]['labels'].pluck('id')).to contain_exactly(development.id)
          expect(json_response[2]['lists']).to be_empty
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_boards', dir: 'ee')
        end

        it 'avoids N+1 queries', :request_store do
          pat = create(:personal_access_token, user: guest)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api(url, personal_access_token: pat), params: params
          end.count

          [testing, feature, development].each do |label|
            board = create(:epic_board, group: group, labels: [testing])
            create(:epic_list, epic_board: board, label: label)
          end

          expect { get api(url, personal_access_token: pat), params: params }
            .not_to exceed_all_query_limit(control)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'GET /groups/:id/epic_boards/:board_id' do
    let(:url) { "/groups/#{group.id}/epic_boards/#{board2.id}" }

    it_behaves_like 'request with epics unavailable'

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it_behaves_like 'request with errors' do
        let(:invalid_url) { "/groups/#{group.id}/epic_boards/#{non_existing_record_id}" }
      end

      context 'when the request is correct' do
        let(:user) { guest }

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(board2.id)
          expect(json_response['labels'].pluck('id')).to contain_exactly(development.id)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_board', dir: 'ee')
        end
      end
    end
  end

  describe 'GET /groups/:id/epic_boards/:board_id/lists' do
    let(:url) { "/groups/#{group.id}/epic_boards/#{board1.id}/lists" }

    it_behaves_like 'request with epics unavailable'

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it_behaves_like 'request with errors' do
        let(:invalid_url) { "/groups/#{group.id}/epic_boards/#{non_existing_record_id}/lists" }
      end

      it_behaves_like 'request with pagination' do
        let(:items) { [list1, list2, list3] }
      end

      context 'when the request is correct' do
        let(:user) { guest }

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to match_array([list1.id, list2.id, list3.id])

          expect(json_response.map { |list| list['label']['name'] })
            .to match_array([development.name, testing.name, feature.name])
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_lists', dir: 'ee')
        end

        it 'avoids N+1 queries', :request_store do
          pat = create(:personal_access_token, user: guest)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            get api(url, personal_access_token: pat), params: params
          end.count

          create_list(:group_label, 3, group: group) do |label|
            create(:epic_list, epic_board: board1, label: label)
          end

          expect { get api(url, personal_access_token: pat), params: params }
            .not_to exceed_all_query_limit(control)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'GET /groups/:id/epic_boards/:board_id/lists/list_id' do
    let(:url) { "/groups/#{group.id}/epic_boards/#{board1.id}/lists/#{list2.id}" }

    it_behaves_like 'request with epics unavailable'

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)

        get api(url, user)
      end

      it_behaves_like 'request with errors' do
        let(:invalid_url) { "/groups/#{group.id}/epic_boards/#{board1.id}/lists/#{non_existing_record_id}" }
      end

      context 'when the request is correct' do
        let(:user) { guest }

        it 'returns 200 status' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(list2.id)
          expect(json_response['label']['id']).to eq(testing.id)
          expect(json_response['position']).to eq(1)
          expect(json_response['list_type']).to eq('label')
          expect(json_response['collapsed']).to eq(false)
        end

        it 'matches the response schema' do
          expect(response).to match_response_schema('public_api/v4/epic_list', dir: 'ee')
        end
      end
    end
  end
end
