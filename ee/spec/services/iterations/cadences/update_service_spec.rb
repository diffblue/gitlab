# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::UpdateService, feature_category: :team_planning do
  subject(:results) { described_class.new(iteration_cadence, user, params).execute }

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:iteration_cadence, refind: true) { create(:iterations_cadence, group: group, start_date: 7.days.from_now, duration_in_weeks: 1, iterations_in_advance: 2) }

  let(:params) do
    {
      title: 'Updated iteration cadence',
      start_date: 2.days.from_now.to_s,
      duration_in_weeks: 4,
      iterations_in_advance: 5,
      roll_over: true,
      description: 'updated cadence description'
    }
  end

  RSpec.shared_examples 'cadence update fails with message' do |message:|
    it { is_expected.to be_error }

    it 'returns not allowed message' do
      expect(results.message).to eq(message)
    end

    it 'does not update cadence values' do
      expect do
        results

        iteration_cadence.reload
      end.to not_change(iteration_cadence, :title).and(
        not_change(iteration_cadence, :start_date)
      ).and(
        not_change(iteration_cadence, :duration_in_weeks)
      ).and(
        not_change(iteration_cadence, :iterations_in_advance)
      )
    end
  end

  describe '#execute' do
    context 'when iterations feature enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      context 'when user is authorized' do
        before do
          group.add_developer(user)
        end

        it { is_expected.to be_success }

        it 'updates cadence values' do
          expect do
            results

            iteration_cadence.reload
          end.to change(iteration_cadence, :title).to('Updated iteration cadence').and(
            change(iteration_cadence, :start_date)
          ).and(
            change(iteration_cadence, :duration_in_weeks).to(4)
          ).and(
            change(iteration_cadence, :iterations_in_advance).to(5)
          ).and(
            change(iteration_cadence, :roll_over).from(false).to(true)
          ).and(
            change(iteration_cadence, :description).to('updated cadence description')
          )
        end

        it 'returns the cadence as part of the response' do
          expect(results.payload[:iteration_cadence]).to eq(iteration_cadence)
        end

        context 'when provided invalid params' do
          let(:params) { { title: '' } }

          it_behaves_like 'cadence update fails with message', message: ["Title can't be blank"]
        end
      end

      context 'when user is not authorized' do
        it_behaves_like 'cadence update fails with message', message: 'Operation not allowed'
      end
    end

    context 'when iterations feature disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      context 'when user is authorized' do
        before do
          group.add_developer(user)
        end

        it_behaves_like 'cadence update fails with message', message: 'Operation not allowed'
      end

      context 'when user is not authorized' do
        it_behaves_like 'cadence update fails with message', message: 'Operation not allowed'
      end
    end
  end
end
