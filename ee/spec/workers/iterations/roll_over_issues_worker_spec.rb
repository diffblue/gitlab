# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::RollOverIssuesWorker, feature_category: :team_planning do
  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }
  let_it_be(:cadence1, reload: true) { create(:iterations_cadence, group: group1, roll_over: true, automatic: true) }
  let_it_be(:cadence2) { create(:iterations_cadence, group: group2, roll_over: true, automatic: true) }
  let_it_be(:closed_iteration1) { create(:iteration, iterations_cadence: cadence1, group: group1, start_date: 2.weeks.ago, due_date: 1.week.ago) }
  let_it_be(:closed_iteration2) { create(:iteration, iterations_cadence: cadence2, group: group2, start_date: 2.weeks.ago, due_date: 1.week.ago) }
  let_it_be(:current_iteration1) { create(:iteration, iterations_cadence: cadence1, group: group1, start_date: 2.days.ago, due_date: 5.days.from_now) }
  let_it_be(:current_iteration2) { create(:iteration, iterations_cadence: cadence2, group: group2, start_date: 2.days.ago, due_date: 5.days.from_now) }

  let(:mock_success_service) { double('mock service', execute: ::ServiceResponse.success) }
  let(:mock_failure_service) { double('mock service', execute: ::ServiceResponse.error(message: 'some error')) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when iteration cadence is not automatic' do
      before do
        cadence1.update_columns(automatic: false)
      end

      it 'exits early' do
        expect(Iterations::RollOverIssuesService).not_to receive(:new)

        worker.perform(group1.iterations)
      end
    end

    context 'when roll-over option on iteration cadence is not enabled' do
      before do
        cadence1.update!(roll_over: false)
      end

      it 'exits early' do
        expect(Iterations::RollOverIssuesService).not_to receive(:new)

        worker.perform(group1.iterations)
      end
    end

    context 'when roll-over option on iteration cadence is enabled' do
      context 'when service fails to create upcoming iteration' do
        it 'logs error' do
          expect(Iterations::RollOverIssuesService).to receive(:new).and_return(mock_failure_service).once
          expect(worker).to receive(:log_error)

          worker.perform(group1.iterations)
        end
      end

      context 'when cadence has upcoming iteration' do
        it 'filters out any iterations that are not closed' do
          expect(Iterations::RollOverIssuesService).to receive(:new).and_return(mock_success_service).once
          expect(Iterations::Cadences::CreateIterationsInAdvanceService).not_to receive(:new)
          expect(Iteration).to receive(:closed).and_call_original.once

          worker.perform(group1.iterations)
        end
      end

      context 'when cadence does not have upcoming iteration' do
        let_it_be(:group) { create(:group) }
        let_it_be(:cadence) { create(:iterations_cadence, group: group, roll_over: true, automatic: true) }
        let_it_be(:closed_iteration) { create(:closed_iteration, iterations_cadence: cadence, group: group, start_date: 2.weeks.ago, due_date: 1.week.ago) }

        it 'creates a new iteration to roll-over issues' do
          expect(Iterations::RollOverIssuesService).to receive(:new).and_return(mock_success_service).once
          expect(Iterations::Cadences::CreateIterationsInAdvanceService).to receive(:new).and_return(mock_success_service)
          expect(Iteration).to receive(:closed).and_call_original.once

          worker.perform(cadence.iterations)
        end

        context 'when service fails to create upcoming iteration' do
          it 'logs error and exits early' do
            expect(Iterations::RollOverIssuesService).not_to receive(:new)
            expect(Iterations::Cadences::CreateIterationsInAdvanceService).to receive(:new).and_return(mock_failure_service)
            expect(worker).to receive(:log_error)

            worker.perform(cadence.iterations)
          end
        end
      end

      it 'avoids N+1 database queries' do
        # warm-up
        User.automation_bot # this create the automation bot user record
        worker.send(:automation_bot) # this will trigger the check and initiate the @automation_bot instance var

        representative = group1.iterations.closed.first
        control_count = ActiveRecord::QueryRecorder.new { worker.perform(representative) }.count

        # for each iteration 2 extra queries are needed:
        # - find the next open iteration
        # - select the open issues to be moved
        # so we have 2 extra closed iterations compared to control count so we need 4 more queries
        iteration_ids = [group1.iterations.closed.pluck(:id) + group2.iterations.closed.pluck(:id)].flatten

        expect { worker.perform(iteration_ids) }.not_to exceed_query_limit(control_count + 4)
      end

      context 'with batches' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it "run in batches" do
          expect(Iterations::RollOverIssuesService).to receive(:new).and_return(mock_success_service).twice
          expect(Iteration).to receive(:closed).and_call_original.exactly(3).times

          iteration_ids = [group1.iterations.closed.pluck(:id) + group2.iterations.closed.pluck(:id)].flatten
          worker.perform(iteration_ids)
        end
      end
    end
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { [group1.iterations] }
  end
end
