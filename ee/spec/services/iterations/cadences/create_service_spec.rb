# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateService, feature_category: :team_planning do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user) { create(:user) }

  before_all do
    group.add_reporter(user)
  end

  shared_examples 'does not create an interation cadence' do |errors|
    it 'does not create an iteration cadence and returns errors' do
      expect(response).to be_error
      expect(errors).to match_array(errors)
    end
  end

  context 'iterations feature enabled' do
    before do
      stub_licensed_features(iterations: true)
    end

    describe '#execute' do
      let(:params) do
        {
          title: 'My iteration cadence',
          start_date: Time.current.to_s,
          duration_in_weeks: 1,
          iterations_in_advance: 1,
          roll_over: true,
          description: 'Iteration cadence description'
        }
      end

      let(:response) { described_class.new(group, user, params).execute }
      let(:iteration_cadence) { response.payload[:iteration_cadence] }
      let(:errors) { response.errors }

      context 'valid params' do
        it 'creates an iteration cadence' do
          expect(response).to be_success
          expect(iteration_cadence).to be_persisted
          expect(iteration_cadence.title).to eq('My iteration cadence')
          expect(iteration_cadence.duration_in_weeks).to eq(1)
          expect(iteration_cadence.iterations_in_advance).to eq(1)
          expect(iteration_cadence.active).to eq(true)
          expect(iteration_cadence.automatic).to eq(true)
        end

        context 'create manual cadence' do
          context 'when duration_in_weeks: nil, start_date: nil and iterations_in_advance: nil' do
            before do
              params.merge!(automatic: false, duration_in_weeks: nil, iterations_in_advance: nil, start_date: nil)
            end

            it 'creates an iteration cadence' do
              expect(response).to be_success
              expect(iteration_cadence).to be_persisted
              expect(iteration_cadence.title).to eq('My iteration cadence')
              expect(iteration_cadence.duration_in_weeks).to be_nil
              expect(iteration_cadence.iterations_in_advance).to be_nil
              expect(iteration_cadence.active).to eq(true)
              expect(iteration_cadence.automatic).to eq(false)
              expect(iteration_cadence.start_date).to be_nil
            end
          end
        end

        context 'create automatic cadence' do
          context 'when start_date is not provided' do
            before do
              params.merge!(automatic: true, duration_in_weeks: 2, iterations_in_advance: 1, start_date: nil)
            end

            it_behaves_like 'does not create an interation cadence', ["Start date can't be blank"]
          end
        end
      end

      context 'invalid params' do
        let(:params) do
          {
            title: 'My iteration cadence'
          }
        end

        context 'when duration_in_weeks: nil and iterations_in_advance: nil' do
          it_behaves_like 'does not create an interation cadence', [
            "Start date can't be blank",
            "Duration in weeks can't be blank",
            "Iterations in advance can't be blank"
          ]
        end

        context 'without of list values for duration_in_weeks and iterations_in_advance' do
          before do
            params.merge!(duration_in_weeks: 15, iterations_in_advance: 15)
          end

          it_behaves_like 'does not create an interation cadence', [
            "Start date can't be blank",
            "Duration in weeks is not included in the list",
            "Iterations in advance is not included in the list"
          ]
        end
      end

      context 'no permissions' do
        before do
          group.add_guest(user)
        end

        it 'is not allowed' do
          expect(response.error?).to be_truthy
          expect(response.message).to eq('Operation not allowed')
        end
      end

      context 'when user cannot create an iterations cadence' do
        let_it_be(:existing_iteration_cadence) { create(:iterations_cadence, group: group) }

        before do
          stub_licensed_features(iterations: false)
        end

        it 'fails to create multiple iteration cadences in same group' do
          expect { response }.not_to change { Iterations::Cadence.count }
        end
      end

      context 'when user can create an iterations cadence' do
        let_it_be(:existing_iteration_cadence) { create(:iterations_cadence, group: group) }

        before do
          stub_licensed_features(iterations: true)
        end

        it 'creates new iteration cadence' do
          expect { response }.to change { Iterations::Cadence.count }.by(1)
        end
      end

      context 'when create cadence can be automated' do
        it 'invokes worker to create iterations in advance' do
          params[:automatic] = true

          expect(::Iterations::Cadences::CreateIterationsWorker).to receive(:perform_async)

          response
        end
      end

      context 'when create cadence is not automated' do
        it 'invokes worker to create iterations in advance' do
          params[:automatic] = false

          expect(::Iterations::Cadences::CreateIterationsWorker).not_to receive(:perform_async)

          response
        end
      end
    end
  end

  context 'iterations feature disabled' do
    before do
      stub_licensed_features(iterations: false)
    end

    describe '#execute' do
      let(:params) { { title: 'a' } }
      let(:response) { described_class.new(group, user, params).execute }

      it 'is not allowed' do
        expect(response.error?).to be_truthy
        expect(response.message).to eq('Operation not allowed')
      end
    end
  end
end
