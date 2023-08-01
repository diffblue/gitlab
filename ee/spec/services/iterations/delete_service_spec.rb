# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::DeleteService, feature_category: :team_planning do
  subject(:results) { described_class.new(iteration_to_delete, user).execute }

  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:start_date) { 3.weeks.ago }
  let_it_be(:iteration_cadence1) { build(:iterations_cadence, group: group, start_date: start_date, duration_in_weeks: 1, iterations_in_advance: 2).tap { |cadence| cadence.save!(validate: false) } }
  let_it_be(:iteration_cadence2) { build(:iterations_cadence, group: group, start_date: start_date, duration_in_weeks: 1, iterations_in_advance: 2).tap { |cadence| cadence.save!(validate: false) } }

  let_it_be(:past_iteration, refind: true) { create(:closed_iteration, iterations_cadence: iteration_cadence1, group: group, start_date: start_date, due_date: start_date + 13.days) }
  let_it_be(:past_board, refind: true) { create(:board, iteration: past_iteration, group: group) }
  let_it_be(:past_issue, refind: true) { create(:issue, project: project, iteration: past_iteration) }
  let_it_be(:past_merge_request, refind: true) { create(:merge_request, source_project: project, iteration: past_iteration) }

  let_it_be(:current_iteration, refind: true) { create(:current_iteration, iterations_cadence: iteration_cadence1, group: group, start_date: start_date + 14.days, due_date: start_date + 27.days) }

  let_it_be(:future_iteration, refind: true) { create(:upcoming_iteration, iterations_cadence: iteration_cadence1, group: group, start_date: start_date + 28.days, due_date: start_date + 41.days) }

  let_it_be(:last_future_iteration, refind: true) { create(:upcoming_iteration, iterations_cadence: iteration_cadence1, group: group, start_date: start_date + 42.days, due_date: start_date + 55.days) }
  let_it_be(:last_future_board, refind: true) { create(:board, iteration: last_future_iteration, group: group) }
  let_it_be(:last_future_issue, refind: true) { create(:issue, project: project, iteration: last_future_iteration) }
  let_it_be(:last_future_merge_request, refind: true) { create(:merge_request, source_branch: 'another-feature', source_project: project, iteration: last_future_iteration) }

  let_it_be(:other_cadence_iteration, refind: true) { create(:current_iteration, iterations_cadence: iteration_cadence2, group: group, start_date: start_date + 14.days, due_date: start_date + 27.days) }
  let_it_be(:other_cadence_board, refind: true) { create(:board, iteration: other_cadence_iteration, group: group) }
  let_it_be(:other_cadence_issue, refind: true) { create(:issue, project: project, iteration: other_cadence_iteration) }
  let_it_be(:other_cadence_merge_request, refind: true) { create(:merge_request, source_branch: 'another-feature2', source_project: project, iteration: other_cadence_iteration) }

  let(:iteration_to_delete) { past_iteration }

  RSpec.shared_examples 'iteration delete fails with message' do |message:|
    it { is_expected.to be_error }

    it 'returns not allowed message' do
      expect(results.message).to eq(message)
    end

    it 'returns the iteration group as part of the response' do
      expect(results.payload[:group]).to eq(group)
    end
  end

  RSpec.shared_examples 'successfully deletes an iteration' do
    it { is_expected.to be_success }

    it 'deletes the iteration and associated records' do
      expect do
        results

        associated_board.reload
        associated_issue.reload
        associated_mr.reload
      end.to change(Iteration, :count).by(-1).and(
        change(List, :count).by(-1)
      ).and(
        change(ResourceIterationEvent, :count).by(-1)
      ).and(
        change(Iteration, :count).by(-1)
      ).and(
        change(associated_board, :iteration_id).from(iteration_to_delete.id).to(nil)
      ).and(
        change(associated_issue, :iteration).from(iteration_to_delete).to(nil)
      ).and(
        change(associated_mr, :iteration).from(iteration_to_delete).to(nil)
      )
    end

    it 'returns the iteration group as part of the response' do
      expect(results.payload[:group]).to eq(group)
    end
  end

  before_all do
    create(:iteration_list, iteration: past_iteration)
    create(:resource_iteration_event, iteration: past_iteration)
    create(:iteration_list, iteration: last_future_iteration)
    create(:resource_iteration_event, iteration: last_future_iteration)
    create(:iteration_list, iteration: other_cadence_iteration)
    create(:resource_iteration_event, iteration: other_cadence_iteration)
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

        context 'when deleting a past iteration' do
          let(:iteration_to_delete) { past_iteration }
          let(:associated_mr) { past_merge_request }
          let(:associated_issue) { past_issue }
          let(:associated_board) { past_board }

          it_behaves_like 'successfully deletes an iteration'
        end

        context 'when deleting the current iteration' do
          let(:iteration_to_delete) { current_iteration }

          it_behaves_like 'iteration delete fails with message', message: ["upcoming/current iterations can't be deleted unless they are the last one in the cadence"]
        end

        context 'when deleting a upcoming iteration that is not the last one' do
          let(:iteration_to_delete) { future_iteration }

          it_behaves_like 'iteration delete fails with message', message: ["upcoming/current iterations can't be deleted unless they are the last one in the cadence"]
        end

        context 'when deleting the last upcoming iteration' do
          let(:iteration_to_delete) { last_future_iteration }
          let(:associated_mr) { last_future_merge_request }
          let(:associated_issue) { last_future_issue }
          let(:associated_board) { last_future_board }

          it_behaves_like 'successfully deletes an iteration'
        end

        context 'when deleting the current iteration in another cadence' do
          let(:iteration_to_delete) { other_cadence_iteration }
          let(:associated_mr) { other_cadence_merge_request }
          let(:associated_issue) { other_cadence_issue }
          let(:associated_board) { other_cadence_board }

          it_behaves_like 'successfully deletes an iteration'
        end
      end

      context 'when user is not authorized' do
        it_behaves_like 'iteration delete fails with message', message: 'Operation not allowed'
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

        it_behaves_like 'iteration delete fails with message', message: 'Operation not allowed'
      end

      context 'when user is not authorized' do
        it_behaves_like 'iteration delete fails with message', message: 'Operation not allowed'
      end
    end
  end
end
