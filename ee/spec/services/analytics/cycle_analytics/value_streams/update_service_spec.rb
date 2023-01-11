# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreams::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let(:params) { {} }

  let(:value_stream) do
    create(:cycle_analytics_value_stream, name: 'VS 1', namespace: group, stages: [
      build(:cycle_analytics_stage, namespace: group, name: 'stage 1', custom: true),
      build(:cycle_analytics_stage, namespace: group, name: 'stage 2', custom: true)
    ])
  end

  let(:first_stage) { value_stream.stages.first }
  let(:last_stage) { value_stream.stages.last }

  subject { described_class.new(value_stream: value_stream, namespace: group, params: params, current_user: user).execute }

  it_behaves_like 'common value stream service examples'

  context 'when the feature is available' do
    before do
      group.add_developer(user)
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'when empty stages are given' do
      let(:params) { { name: 'VS 1', stages: [] } }

      it 'removes the stages' do
        expect(subject).to be_success
        expect(subject.payload[:value_stream].reload.stages).to be_empty
      end
    end

    context 'updating one stage within a value stream' do
      let(:params) do
        {
          name: 'VS 1',
          stages: [
            { id: first_stage.id, name: first_stage.name, custom: true },
            { id: last_stage.id, name: 'updated', custom: true }
          ]
        }
      end

      it 'updates the stage' do
        expect(subject).to be_success
        expect(last_stage.reload.name).to eq('updated')
      end

      context 'relative positioning' do
        before do
          params[:stages].reverse!
        end

        it 'calculates and sets relative_position for the stages based on the incoming stages array' do
          incoming_stage_names = params[:stages].map { |stage| stage[:name] }

          value_stream = subject.payload[:value_stream]
          persisted_stages_sorted_by_relative_position = value_stream.stages.sort_by(&:relative_position).map(&:name)

          expect(persisted_stages_sorted_by_relative_position).to eq(incoming_stage_names)
        end
      end

      context 'when the params are invalid' do
        before do
          params[:stages].last[:name] = ''
        end

        it 'returns error' do
          expect(subject).to be_error
          errors = subject.payload[:errors].details
          expect(errors[:'stages[1].name']).to eq([{ error: :blank }])
        end
      end
    end

    context 'adding a new stage within a value stream' do
      let(:params) do
        {
          name: 'VS 1',
          stages: [
            { id: first_stage.id, name: first_stage.name, custom: true },
            { id: last_stage.id, name: last_stage.name, custom: true },
            { name: 'new stage', custom: true, start_event_identifier: 'merge_request_created', end_event_identifier: 'merge_request_closed' }
          ]
        }
      end

      it 'creates the stage' do
        expect(subject).to be_success
        expect(subject.payload[:value_stream].stages.last.name).to eq('new stage')
      end
    end

    context 'when adding a default stage' do
      let(:params) do
        {
          name: 'VS 1',
          stages: [
            { id: first_stage.id, name: first_stage.name, custom: true },
            { id: last_stage.id, name: last_stage.name, custom: true },
            { name: 'plan', custom: false }
          ]
        }
      end

      it 'creates the stage' do
        expect(subject).to be_success
        expect(subject.payload[:value_stream].stages.last.name).to eq('plan')
      end
    end

    context 'when removing a stage and adding a new stage' do
      let(:params) do
        {
          name: 'VS 1',
          stages: [
            { id: first_stage.id, name: first_stage.name, custom: true },
            { name: 'new stage', custom: true, start_event_identifier: 'merge_request_created', end_event_identifier: 'merge_request_closed' }
          ]
        }
      end

      it 'creates the stage' do
        expect(subject).to be_success

        current_stage_names = subject.payload[:value_stream].stages.map(&:name)
        expect(current_stage_names).to match_array([first_stage.name, 'new stage'])
      end
    end
  end
end
