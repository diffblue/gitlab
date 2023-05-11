# frozen_string_literal: true

RSpec.shared_examples 'Value Stream Analytics Stages controller' do
  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #index' do
    subject { get :index, params: params }

    it 'succeeds' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('analytics/cycle_analytics/stages', dir: 'ee')
    end

    it 'returns correct start events' do
      subject

      response_start_events = json_response['stages'].map { |s| s['start_event_identifier'] }
      start_events = stages.map { |s| s['start_event_identifier'] }

      expect(response_start_events).to eq(start_events)
    end

    it 'does not include internal events' do
      subject

      response_event_names = json_response['events'].map { |s| s['name'] }
      event_names = Gitlab::Analytics::CycleAnalytics::StageEvents.events
      internal_events = Gitlab::Analytics::CycleAnalytics::StageEvents.internal_events
      expected_event_names = (event_names - internal_events).map(&:name)

      expect(response_event_names).to eq(expected_event_names.sort)
    end

    it 'succeeds for subgroups' do
      subgroup = create(:group, parent: group)
      params[:group_id] = subgroup.full_path
      params[:value_stream_id] = create(:cycle_analytics_value_stream, namespace: subgroup).id

      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders `forbidden` based on the response of the service object' do
      stub_licensed_features(cycle_analytics_for_groups: false)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    include_examples 'group permission check on the controller level'
  end

  describe 'data endpoints' do
    let(:stage) { create(:cycle_analytics_stage, namespace: group) }

    before do
      params[:id] = stage.id
    end

    describe 'GET #median' do
      subject { get :median, params: params }

      it 'matches the response schema' do
        subject

        expect(response).to match_response_schema('analytics/cycle_analytics/number_or_nil_value', dir: 'ee')
      end

      include_examples 'Value Stream Analytics data endpoint examples'
    end

    describe 'GET #average' do
      subject { get :average, params: params }

      it 'matches the response schema' do
        subject

        expect(response).to match_response_schema('analytics/cycle_analytics/number_or_nil_value', dir: 'ee')
      end

      include_examples 'Value Stream Analytics data endpoint examples'
    end

    describe 'GET #records' do
      subject { get :records, params: params }

      include_examples 'Value Stream Analytics data endpoint examples'
      include_examples 'group permission check on the controller level'

      context 'sort params' do
        before do
          params.merge!(sort: 'duration', direction: 'asc')
        end

        it 'accepts sort params' do
          travel_to DateTime.new(2019, 1, 5) do
            event_1 = create(
              :cycle_analytics_merge_request_stage_event,
              stage_event_hash_id: stage.stage_event_hash_id,
              group_id: stage.namespace.id,
              merge_request_id: 1,
              start_event_timestamp: Time.current,
              end_event_timestamp: 20.days.from_now
            )

            event_2 = create(
              :cycle_analytics_merge_request_stage_event,
              stage_event_hash_id: stage.stage_event_hash_id,
              group_id: stage.namespace.id,
              merge_request_id: 2,
              start_event_timestamp: Time.current,
              end_event_timestamp: 1.day.from_now
            )

            event_3 = create(
              :cycle_analytics_merge_request_stage_event,
              stage_event_hash_id: stage.stage_event_hash_id,
              group_id: stage.namespace.id,
              merge_request_id: 3,
              start_event_timestamp: Time.current,
              end_event_timestamp: 3.days.from_now
            )

            expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher) do |records_fetcher|
              records_fetcher.serialized_records do |raw_active_record_scope|
                expect(raw_active_record_scope.pluck(:merge_request_id)).to eq([event_2.merge_request_id, event_3.merge_request_id, event_1.merge_request_id])
              end
            end
          end

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'pagination' do
        it 'exposes pagination headers' do
          create_list(:cycle_analytics_merge_request_stage_event, 3)
          stub_const('Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher::MAX_RECORDS', 2)

          allow_any_instance_of(Gitlab::Analytics::CycleAnalytics::Aggregated::RecordsFetcher).to receive(:query).and_return(Analytics::CycleAnalytics::MergeRequestStageEvent.all)

          subject

          expect(response.headers['X-Next-Page']).to eq('2')
          expect(response.headers['Link']).to include('rel="next"')
        end
      end
    end

    describe 'GET #average_duration_chart' do
      subject { get :average_duration_chart, params: params }

      it 'matches the response schema' do
        fake_result = [double(MergeRequest, average_duration_in_seconds: 10, date: params[:created_after])]

        expect_any_instance_of(Gitlab::Analytics::CycleAnalytics::Aggregated::DataForDurationChart).to receive(:average_by_day).and_return(fake_result)

        subject

        expect(response).to match_response_schema('analytics/cycle_analytics/average_duration_chart', dir: 'ee')
      end

      it 'fills all dates between the given range' do
        subject

        expected_dates = (Date.parse(params[:created_after])..Date.parse(params[:created_before])).map(&:to_s)
        actual_dates = json_response.map { |datapoint| datapoint['date'] }

        expect(actual_dates).to eq(expected_dates)
      end

      include_examples 'Value Stream Analytics data endpoint examples'
      include_examples 'group permission check on the controller level'
    end

    describe 'GET #count' do
      subject { get :count, params: params }

      it 'matches the response schema' do
        subject

        expect(response).to be_successful
        expect(json_response['count']).to eq(0)
      end

      include_examples 'Value Stream Analytics data endpoint examples'
      include_examples 'group permission check on the controller level'
    end
  end
end

RSpec.shared_examples 'group permission check on the controller level' do
  context 'when `group_id` is not found' do
    before do
      params[:group_id] = 'missing_group'
    end

    it 'renders `not_found` when group is missing' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when user has no lower access level than `reporter`' do
    before do
      GroupMember.where(user: user).delete_all
      group.add_guest(user)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when feature is not available for the group' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: false)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

RSpec.shared_context 'when invalid stage parameters are given' do
  before do
    params[:name] = ''
  end

  it 'renders the validation errors' do
    subject

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
  end
end

RSpec.shared_examples 'Value Stream Analytics data endpoint examples' do
  before do
    params[:created_after] = '2019-01-01'
    params[:created_before] = '2019-04-01'
  end

  context 'when valid parameters are given' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
    end
  end

  context 'accepts optional `project_ids` array' do
    before do
      params[:project_ids] = [1, 2, 3]
    end

    it 'succeeds' do
      expect_any_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams).to receive(:project_ids=).with(%w[1 2 3]).and_call_original

      subject

      expect(response).to be_successful
    end
  end

  shared_examples 'example for invalid parameter' do
    it 'renders `unprocessable_entity`' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
    end
  end

  context 'when `created_before` is missing' do
    before do
      params.delete(:created_before)
    end

    it 'succeeds' do
      travel_to '2019-04-01' do
        subject

        expect(response).to be_successful
      end
    end
  end

  context 'when `created_after` is missing' do
    before do
      params.delete(:created_after)
    end

    it 'succeeds' do
      subject

      expect(response).to be_successful
    end
  end

  context 'when `created_after` is invalid, falls back to default date' do
    before do
      params[:created_after] = 'not-a-date'
    end

    it { expect(subject).to have_gitlab_http_status(:success) }
  end

  context 'when `created_before` is invalid' do
    before do
      params[:created_before] = 'not-a-date'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_after` is later than `created_before`' do
    before do
      params[:created_after] = '2012-01-01'
      params[:created_before] = '2010-01-01'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when the date range exceeds 180 days' do
    before do
      params[:created_after] = '2019-01-01'
      params[:created_before] = '2019-08-01'
    end

    include_examples 'example for invalid parameter'
  end
end
