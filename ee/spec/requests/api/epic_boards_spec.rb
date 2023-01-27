# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::EpicBoards, feature_category: :portfolio_management do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let_it_be(:group, reload: true) { create(:group, :private) }
  let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
  let_it_be(:testing) { create(:group_label, group: group, name: 'Testing') }

  let_it_be(:board1) { create(:epic_board, group: group) }
  let_it_be(:board2) { create(:epic_board, group: group, labels: [development]) }
  let_it_be(:board3) { create(:epic_board, group: group) }
  let_it_be(:board4) { create(:epic_board) }

  let_it_be(:list1) { create(:epic_list, epic_board: board1, label: development, position: 0) }
  let_it_be(:list2) { create(:epic_list, epic_board: board1, label: testing, position: 0) }

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
          expect(json_response[0]['lists'].pluck('id')).to match_array([list1.id, list2.id])
          expect(json_response[0]['lists'].map { |list| list['label']['name'] })
            .to match_array([development.name, testing.name])

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

          board = create(:epic_board, group: group, labels: [testing])
          create(:epic_list, epic_board: board, label: development)

          expect { get api(url, personal_access_token: pat), params: params }
            .not_to exceed_all_query_limit(control)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with pagination params' do
      let(:page) { 1 }
      let(:per_page) { 2 }

      before do
        stub_licensed_features(epics: true)
      end

      shared_examples 'paginated API endpoint' do
        it 'returns the correct page' do
          get api(url, guest), params: { page: page, per_page: per_page }

          expect(response.headers['X-Page']).to eq(page.to_s)
          expect_paginated_array_response(expected)
        end
      end

      context 'when viewing the first page' do
        let(:expected) { [board1.id, board2.id] }
        let(:page) { 1 }

        it_behaves_like 'paginated API endpoint'
      end

      context 'when viewing the second page' do
        let(:expected) { [board3.id] }
        let(:page) { 2 }

        it_behaves_like 'paginated API endpoint'
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
end
