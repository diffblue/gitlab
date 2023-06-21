# frozen_string_literal: true

RSpec.shared_examples 'supports keyset pagination' do
  include KeysetPaginationHelpers

  it 'paginates the records correctly' do
    get api(url, admin, admin_mode: true), params: { pagination: 'keyset', per_page: 1 }

    expect(response).to have_gitlab_http_status(:ok)
    records = json_response
    expect(records.size).to eq(1)
    expect(records.first['id']).to eq(audit_event_2.id)

    params_for_next_page = pagination_params_from_next_url(response)
    expect(params_for_next_page).to include('cursor')

    get api(url, admin), params: params_for_next_page

    expect(response).to have_gitlab_http_status(:ok)
    records = Gitlab::Json.parse(response.body)
    expect(records.size).to eq(1)
    expect(records.first['id']).to eq(audit_event_1.id)
  end

  context 'on making requests with unsupported ordering structure' do
    it 'returns error' do
      get api(url, admin, admin_mode: true),
        params: { pagination: 'keyset', per_page: 1, order_by: 'created_at', sort: 'asc' }

      expect(response).to have_gitlab_http_status(:method_not_allowed)
      expect(json_response['error']).to eq('Keyset pagination is not yet available for this type of request')
    end
  end
end
