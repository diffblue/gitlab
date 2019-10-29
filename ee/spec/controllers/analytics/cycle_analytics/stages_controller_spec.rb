# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalytics::StagesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }
  let(:params) { { group_id: group.full_path } }

  before do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  describe 'GET `index`' do
    subject { get :index, params: params }

    it 'succeeds' do
      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/cycle_analytics/stages', dir: 'ee')
    end

    it 'returns correct start events' do
      subject

      response_start_events = json_response['stages'].map { |s| s['start_event_identifier'] }
      start_events = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map { |s| s['start_event_identifier'] }

      expect(response_start_events).to eq(start_events)
    end

    it 'returns correct event names' do
      subject

      response_event_names = json_response['events'].map { |s| s['name'] }
      event_names = Gitlab::Analytics::CycleAnalytics::StageEvents.events.map(&:name)

      expect(response_event_names).to eq(event_names)
    end

    it 'succeeds for subgroups' do
      subgroup = create(:group, parent: group)
      params[:group_id] = subgroup.full_path

      subject

      expect(response).to be_successful
    end

    it 'renders `forbidden` based on the response of the service object' do
      expect_any_instance_of(Analytics::CycleAnalytics::Stages::ListService).to receive(:can?).and_return(false)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    include_examples 'group permission check on the controller level'
  end

  describe 'POST `create`' do
    subject { post :create, params: params }

    include_examples 'group permission check on the controller level'

    context 'when valid parameters are given' do
      before do
        params.merge!({
          name: 'my new stage',
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged
        })
      end

      it 'creates the stage' do
        subject

        expect(response).to be_successful
        expect(response).to match_response_schema('analytics/cycle_analytics/stage', dir: 'ee')
      end
    end

    include_context 'when invalid stage parameters are given'
  end

  describe 'PUT `update`' do
    let(:stage) { create(:cycle_analytics_group_stage, parent: group) }
    subject { put :update, params: params.merge(id: stage.id) }

    include_examples 'group permission check on the controller level'

    context 'when valid parameters are given' do
      before do
        params.merge!({
          name: 'my updated stage',
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged
        })
      end

      it 'succeeds' do
        subject

        expect(response).to be_successful
        expect(response).to match_response_schema('analytics/cycle_analytics/stage', dir: 'ee')
      end

      it 'updates the name attribute' do
        subject

        stage.reload

        expect(stage.name).to eq(params[:name])
      end
    end

    include_context 'when invalid stage parameters are given'
  end

  describe 'DELETE `destroy`' do
    let(:stage) { create(:cycle_analytics_group_stage, parent: group) }

    subject { delete :destroy, params: params }

    before do
      params[:id] = stage.id
    end

    include_examples 'group permission check on the controller level'

    context 'when persisted stage id is passed' do
      it 'succeeds' do
        subject

        expect(response).to be_successful
      end

      it 'deletes the record' do
        subject

        expect(group.reload.cycle_analytics_stages.find_by(id: stage.id)).to be_nil
      end
    end

    context 'when default stage id is passed' do
      before do
        params[:id] = Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first
      end

      it 'fails with `forbidden` response' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'GET `median`' do
      subject { get :median, params: params }

      before do
        params[:created_after] = '2019-01-01'
        params[:created_before] = '2020-01-01'
      end

      it 'succeeds' do
        subject

        expect(response).to be_successful
        expect(response).to match_response_schema('analytics/cycle_analytics/median', dir: 'ee')
      end

      context 'when params are invalid' do
        before do
          params[:created_before] = '2018-01-01'
        end

        it 'renders `unprocessable_entity`' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
        end
      end

      include_examples 'group permission check on the controller level'
    end

    describe 'GET `records`' do
      subject { get :records, params: params }

      before do
        params[:created_after] = '2019-01-01'
        params[:created_before] = '2020-01-01'
      end

      it 'succeeds' do
        subject

        expect(response).to be_successful
      end

      include_examples 'group permission check on the controller level'
    end
  end
end
