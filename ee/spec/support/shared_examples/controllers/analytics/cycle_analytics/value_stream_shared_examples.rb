# frozen_string_literal: true

RSpec.shared_examples 'value stream controller actions' do
  let_it_be(:value_streams) do
    [
      create(
        :cycle_analytics_value_stream,
        namespace: namespace,
        name: 'First value stream'
      ),
      create(
        :cycle_analytics_value_stream,
        namespace: namespace,
        name: 'Second value stream'
      )
    ]
  end

  let(:stage_params) do
    [
      { start_event_identifier: :issue_created, end_event_identifier: :issue_closed, name: 'issue time', custom: true },
      { start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_closed, name: 'mr time',
custom: true }
    ]
  end

  def path_for(path_postfix)
    Rails.application.routes.url_helpers.polymorphic_path(path_prefix + Array(path_postfix), **params)
  end

  before do
    stub_licensed_features(license_name => true)
    group.add_developer(user)
    login_as(user)
  end

  shared_examples 'authorization examples' do
    context 'when not licensed' do
      before do
        stub_licensed_features(license_name => false)
      end

      it 'renders 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not a member' do
      it 'renders 404' do
        login_as(another_user)

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET index' do
    subject(:request) { get path_for(%i[analytics cycle_analytics value_streams]) }

    context 'when user is a member' do
      it 'returns the persisted value streams' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        ids = json_response.pluck('id')
        expect(ids).to match_array(value_streams.pluck(:id))
      end
    end

    context 'when user is not a member' do
      it 'renders 404' do
        login_as(another_user)

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    let(:value_stream) { value_streams.first }

    subject(:request) { get path_for(value_stream) }

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('analytics/cycle_analytics/value_stream', dir: 'ee')
    end

    context 'when value stream is not found' do
      it 'renders 404' do
        Analytics::CycleAnalytics::ValueStream.find(value_stream.id).delete

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'authorization examples'
  end

  describe 'GET #new' do
    subject(:request) { get path_for(%i[analytics cycle_analytics value_stream]) }

    before do
      path_prefix.unshift(:new)
    end

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:ok)
    end

    it_behaves_like 'authorization examples'
  end

  describe 'GET #edit' do
    let(:value_stream) { value_streams.first }

    subject(:request) { get path_for(value_stream) }

    before do
      path_prefix.unshift(:edit)
    end

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when value stream is not found' do
      it 'renders 404 not found' do
        Analytics::CycleAnalytics::ValueStream.find(value_stream.id).delete

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'authorization examples'
  end

  describe 'PUT #update' do
    let(:value_stream) { value_streams.first }
    let(:value_stream_params) { { name: 'renamed', stages: stage_params } }

    subject(:request) { put path_for(value_stream), params: { value_stream: value_stream_params } }

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['name']).to eq('renamed')
    end

    context 'when validation error happens' do
      before do
        value_stream_params[:name] = ''
      end

      it 'returns 422 unprocessable entity' do
        request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when value stream is not found' do
      it 'renders 404 not found' do
        Analytics::CycleAnalytics::ValueStream.find(value_stream.id).delete

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when updating value stream with in-memory stages' do
      let(:value_stream_params) do
        {
          name: 'updated name',
          stages: [
            {
              id: 'issue', # in memory stage
              name: 'issue',
              custom: false
            }
          ]
        }
      end

      it 'returns a successful 200 response' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('updated name')
      end
    end

    context 'when deleting the stage by excluding it from the stages array' do
      let(:value_stream_params) { { name: 'no stages', stages: [] } }

      it 'returns a successful 200 response' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['stages']).to be_empty
      end
    end

    it_behaves_like 'authorization examples'
  end

  describe 'POST #create' do
    let(:value_stream_params) { { name: 'new', stages: stage_params } }

    subject(:request) do
      post path_for(%i[analytics cycle_analytics value_streams]), params: { value_stream: value_stream_params }
    end

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq('new')
    end

    context 'when validation error happens' do
      before do
        value_stream_params[:name] = ''
      end

      it 'returns 422 unprocessable entity' do
        request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    it_behaves_like 'authorization examples'
  end

  describe 'DELETE #destroy' do
    let(:value_stream) { value_streams.first }

    subject(:request) { delete path_for(value_stream) }

    it 'succeeds' do
      request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when value stream is not found' do
      it 'renders 404 not found' do
        Analytics::CycleAnalytics::ValueStream.find(value_stream.id).delete

        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'authorization examples'
  end
end
