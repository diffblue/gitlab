# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStreams::CreateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let(:params) { {} }

  subject { described_class.new(namespace: group, params: params, current_user: user).execute }

  it_behaves_like 'common value stream service examples'

  context 'when the feature is available' do
    before do
      group.add_developer(user)
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'when stage params are passed' do
      let(:params) do
        {
          name: 'my value stream',
          stages: [
            {
              name: 'Custom stage 1',
              start_event_identifier: 'merge_request_created',
              end_event_identifier: 'merge_request_closed',
              custom: true
            },
            {
              name: 'Custom stage 2',
              start_event_identifier: 'issue_created',
              end_event_identifier: 'issue_closed',
              custom: true
            }
          ]
        }
      end

      it 'persists the value stream record' do
        expect(subject).to be_success
        expect(subject.payload[:value_stream]).to be_persisted
      end

      it 'persists the stages' do
        value_stream = subject.payload[:value_stream]

        expect(value_stream.stages.size).to eq(2)
      end

      it 'calculates and sets relative_position for the stages based on the incoming stages array' do
        incoming_stage_names = params[:stages].map { |stage| stage[:name] }

        value_stream = subject.payload[:value_stream]
        persisted_stages_sorted_by_relative_position = value_stream.stages.sort_by(&:relative_position).map(&:name)

        expect(persisted_stages_sorted_by_relative_position).to eq(incoming_stage_names)
      end

      context 'when the stage is invalid' do
        it 'propagates validation errors' do
          params[:stages].first[:name] = ''

          errors = subject.payload[:errors].details
          expect(errors[:'stages[0].name']).to eq([{ error: :blank }])
        end
      end

      context 'when creating a default stage' do
        before do
          params[:stages] = [{ id: 'plan', name: 'plan', custom: false }]
        end

        let(:custom_stage) { subject.payload[:value_stream].stages.first }

        it 'persists the stage as custom stage' do
          expect(subject).to be_success
          expect(custom_stage).to be_persisted
        end
      end

      context 'when no stage params are passed' do
        let(:params) { { name: 'test' } }

        it 'persists the value stream record' do
          expect(subject).to be_success
          expect(subject.payload[:value_stream]).to be_persisted
        end
      end
    end
  end
end
