# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::ScheduleCreateIterationsWorker, :freeze_time, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'in batches' do
      let_it_be(:iteration_cadences) { create_list(:iterations_cadence, 2, group: group, start_date: 6.days.ago, duration_in_weeks: 1, iterations_in_advance: 2) }

      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'run in batches' do
        expect(Iterations::Cadences::CreateIterationsWorker).to receive(:perform_async).twice
        expect(Iterations::Cadence).to receive(:next_to_auto_schedule).and_call_original.once

        worker.perform
      end
    end

    context 'when cadences need to be scheduled' do
      let_it_be(:common_args) { { group: group, start_date: Date.current, duration_in_weeks: 1, iterations_in_advance: 2 } }
      let_it_be(:scheduled_cadence) { create(:iterations_cadence, **common_args, next_run_date: Date.current + 5.days) }

      shared_examples 'CreateIterationsWorker is scheduled on the correct cadence' do
        it 'schedules CreateIterationsWorker on the correct cadence' do
          expect(Iterations::Cadences::CreateIterationsWorker).to receive(:perform_async).with(next_cadence.id).once

          worker.perform
        end
      end

      context 'when cadence with NULL next_run_date exists' do
        let_it_be(:next_cadence) { create(:iterations_cadence, **common_args, next_run_date: nil) }

        it_behaves_like 'CreateIterationsWorker is scheduled on the correct cadence'
      end

      context 'when cadence with next_run_date < CURRENT_DATE exists' do
        let_it_be(:next_cadence) { create(:iterations_cadence, group: group, **common_args, next_run_date: Date.current - 5.days) }

        it_behaves_like 'CreateIterationsWorker is scheduled on the correct cadence'
      end
    end
  end

  include_examples 'an idempotent worker'
end
