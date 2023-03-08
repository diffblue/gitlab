# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::DestroyService, feature_category: :team_planning do
  subject(:results) { described_class.new(iteration_cadence, user).execute }

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:iteration_cadence, refind: true) { create(:iterations_cadence, group: group, start_date: Date.today, duration_in_weeks: 1, iterations_in_advance: 2) }
  let_it_be(:iteration) { create(:current_iteration, group: group, iterations_cadence: iteration_cadence, start_date: 2.days.ago, due_date: 5.days.from_now) }
  let_it_be(:iteration_list, refind: true) { create(:iteration_list, iteration: iteration) }
  let_it_be(:iteration_event, refind: true) { create(:resource_iteration_event, iteration: iteration) }
  let_it_be(:board, refind: true) { create(:board, iteration: iteration, iteration_cadence: iteration_cadence, group: group) }
  let_it_be(:board2, refind: true) { create(:board, iteration: iteration, group: group) }
  let_it_be(:issue) { create(:issue, project: project, iteration: iteration) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, iteration: iteration) }

  RSpec.shared_examples 'cadence destroy fails with message' do |message:|
    it { is_expected.to be_error }

    it 'returns not allowed message' do
      expect(results.message).to eq(message)
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

        it 'destroys the cadence and associated records' do
          expect do
            results
            board.reload
            board2.reload
            issue.reload
            merge_request.reload
          end.to change(Iterations::Cadence, :count).by(-1).and(
            change(List, :count).by(-1)
          ).and(
            change(ResourceIterationEvent, :count).by(-1)
          ).and(
            change(Iteration, :count).by(-1)
          ).and(
            change(board, :iteration_id).from(iteration.id).to(nil)
          ).and(
            change(board2, :iteration_id).from(iteration.id).to(nil)
          ).and(
            change(board, :iteration_cadence_id).from(iteration_cadence.id).to(nil)
          ).and(
            change(issue, :iteration).from(iteration).to(nil)
          ).and(
            change(merge_request, :iteration).from(iteration).to(nil)
          )
        end

        it 'returns the cadence as part of the response' do
          expect(results.payload[:iteration_cadence]).to eq(iteration_cadence)
        end
      end

      context 'when user is not authorized' do
        it_behaves_like 'cadence destroy fails with message', message: 'Operation not allowed'
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

        it_behaves_like 'cadence destroy fails with message', message: 'Operation not allowed'
      end

      context 'when user is not authorized' do
        it_behaves_like 'cadence destroy fails with message', message: 'Operation not allowed'
      end
    end
  end
end
