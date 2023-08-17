# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Snippets, :aggregate_failures, feature_category: :source_code_management do
  include SnippetHelpers

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:storage) { "default" }
  let_it_be(:snippet1) { create(:snippet, :repository, author: admin) }
  let_it_be(:snippet2) { create(:snippet, :repository, author: user) }
  let_it_be(:snippet3) { create(:snippet, repository_storage: "extra", author: admin) }

  describe 'GET /snippets/all' do
    let(:path) { "/snippets/all" }

    context 'when repository storage name is specified' do
      context 'for an admin', :enable_admin_mode do
        it 'returns all snippets' do
          get api(path, admin)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(3)
        end

        it 'filters by the repository storage name' do
          get api(path, admin), params: { repository_storage: storage }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(2)
          expect(json_response.first['repository_storage']).to eq(storage)
        end

        it 'does not return any snippet for unknown storage' do
          get api(path, admin), params: { repository_storage: "#{storage}-unknown" }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(0)
        end
      end

      context 'for a user' do
        it 'the repository storage filter is ignored' do
          get api(path, user), params: { repository_storage: storage }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(1)
          expect(json_response).to all exclude('repository_storage')
        end
      end
    end
  end
end
