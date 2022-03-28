# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::ValueStreamsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let(:params) { { group_id: group } }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns an in-memory default value stream' do
      get :index, params: params

      expect(response).to have_gitlab_http_status(:ok)

      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME)
      expect(json_response.first['name']).to eq(Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME)
    end

    context 'when persisted value streams present' do
      let!(:value_stream) { create(:cycle_analytics_group_value_stream, group: group) }

      it 'succeeds' do
        get :index, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('analytics/cycle_analytics/value_streams', dir: 'ee')
        expect(json_response.first['id']).to eq(value_stream.id)
        expect(json_response.first['name']).to eq(value_stream.name)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'returns a successful 200 response' do
        expect do
          post :create, params: { group_id: group, value_stream: { name: "busy value stream" } }
        end.to change { Analytics::CycleAnalytics::GroupValueStream.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'with invalid params' do
      it 'returns an unprocessable entity 422 response' do
        expect do
          post :create, params: { group_id: group, value_stream: { name: '' } }
        end.not_to change { Analytics::CycleAnalytics::GroupValueStream.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response["message"]).to eq('Invalid parameters')
      end
    end

    context 'with stages' do
      let(:value_stream_params) do
        {
          name: 'test',
          stages: [
            {
              name: 'My Stage',
              start_event_identifier: 'issue_created',
              end_event_identifier: 'issue_closed',
              custom: true
            }
          ]
        }
      end

      it 'persists the value stream with stages' do
        post :create, params: { group_id: group, value_stream: value_stream_params }

        expect(response).to have_gitlab_http_status(:created)
        stage_response = json_response['stages'].first
        expect(stage_response['title']).to eq('My Stage')
      end

      context 'when using the new start and end event params format' do
        let(:value_stream_params) do
          {
            name: 'test',
            stages: [
              {
                name: 'My Stage',
                start_event: {
                  identifier: 'issue_created'
                },
                end_event: {
                  identifier: 'issue_closed'
                },
                custom: true
              }
            ]
          }
        end

        it 'succeeds' do
          post :create, params: { group_id: group, value_stream: value_stream_params }

          expect(response).to have_gitlab_http_status(:created)
          stage_response = json_response['stages'].first
          expect(stage_response['title']).to eq('My Stage')
        end
      end

      context 'when invalid stage is given' do
        before do
          value_stream_params[:stages].first[:name] = ''
        end

        it 'renders errors with unprocessable entity, 422 response' do
          post :create, params: { group_id: group, value_stream: value_stream_params }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          stage_errors = json_response['payload']['errors']['stages']['0']
          expect(stage_errors).to be_present
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let!(:value_stream) { create(:cycle_analytics_group_value_stream, group: group, name: 'value stream') }

      it 'returns a successful 200 response' do
        put :update, params: { id: value_stream.id, group_id: group, value_stream: { name: 'new name' } }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('new name')
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
          put :update, params: { id: value_stream.id, group_id: group, value_stream: value_stream_params }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq('updated name')
        end
      end

      context 'with stages' do
        let!(:stage) { create(:cycle_analytics_group_stage, group: group, value_stream: value_stream, name: 'stage 1', custom: true) }

        let(:value_stream_params) do
          {
            name: 'updated name',
            stages: [
              {
                id: stage.id,
                name: 'updated stage name',
                custom: true
              }
            ]
          }
        end

        it 'returns a successful 200 response' do
          put :update, params: { id: value_stream.id, group_id: group, value_stream: value_stream_params }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq('updated name')
          expect(json_response['id']).to eq(value_stream.id)
          expect(json_response['stages'].first['title']).to eq('updated stage name')
        end

        context 'when using the new start and end event params format' do
          let(:value_stream_params) do
            {
              name: 'test',
              id: value_stream.id,
              stages: [
                {
                  id: stage.id,
                  name: 'updated stage name',
                  start_event: {
                    identifier: 'issue_created'
                  },
                  end_event: {
                    identifier: 'issue_closed'
                  },
                  custom: true
                }
              ]
            }
          end

          it 'succeeds' do
            put :update, params: { id: value_stream.id, group_id: group, value_stream: value_stream_params }

            expect(response).to have_gitlab_http_status(:ok)
            start_event_identifier = json_response['stages'].first['start_event']['identifier']
            end_event_identifier = json_response['stages'].first['end_event']['identifier']

            expect(start_event_identifier).to eq('issue_created')
            expect(end_event_identifier).to eq('issue_closed')
          end
        end

        context 'when deleting the stage by excluding it from the stages array' do
          let(:value_stream_params) { { name: 'no stages', stages: [] } }

          it 'returns a successful 200 response' do
            put :update, params: { id: value_stream.id, group_id: group, value_stream: value_stream_params }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['stages']).to be_empty
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    def destroy_value_stream
      delete :destroy, params: { group_id: group, id: value_stream }
    end

    context 'when it is a custom value stream' do
      let!(:value_stream) { create(:cycle_analytics_group_value_stream, group: group, name: 'some custom value stream') }
      let!(:stage) { create(:cycle_analytics_group_stage, value_stream: value_stream) }

      it 'deletes the value stream and its stages, and returns a successful 200 response' do
        expect { destroy_value_stream }.to change { Analytics::CycleAnalytics::GroupValueStream.count }.by(-1)
          .and change { Analytics::CycleAnalytics::GroupStage.where(value_stream: value_stream).count }.from(1).to(0)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
