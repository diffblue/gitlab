# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IterationsUpdateStatusWorker, feature_category: :team_planning do
  let_it_be(:closed_iteration1, reload: true) { create(:iteration, :skip_future_date_validation, start_date: 20.days.ago, due_date: 11.days.ago) }
  let_it_be(:current_iteration1, reload: true) { create(:iteration, :skip_future_date_validation, start_date: 10.days.ago, due_date: 3.days.ago) }
  let_it_be(:current_iteration2) { create(:iteration, :skip_future_date_validation, start_date: 2.days.ago, due_date: 5.days.from_now) }
  let_it_be(:upcoming_iteration) { create(:iteration, start_date: 11.days.from_now, due_date: 13.days.from_now) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      current_iteration1.update_column(:state_enum, Iteration::STATE_ENUM_MAP[:current])
      closed_iteration1.update_column(:state_enum, Iteration::STATE_ENUM_MAP[:upcoming])
    end

    it 'schedules an issues roll-over job' do
      expect(Iterations::RollOverIssuesWorker).to receive(:perform_async)

      worker.perform
    end

    context 'when iterations with passed due dates are in `upcoming`, `current` or `closes` states' do
      it 'updates the status of iterations that require it', :aggregate_failures do
        expect(closed_iteration1.state).to eq('upcoming')
        expect(current_iteration1.state).to eq('current')
        expect(current_iteration2.state).to eq('current')
        expect(upcoming_iteration.state).to eq('upcoming')

        worker.perform

        expect(closed_iteration1.reload.state).to eq('closed')
        expect(current_iteration1.reload.state).to eq('closed')
        expect(current_iteration2.reload.state).to eq('current')
        expect(upcoming_iteration.reload.state).to eq('upcoming')
      end

      context 'in batches' do
        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it "run in batches" do
          expect(Iterations::RollOverIssuesWorker).to receive(:perform_async).twice

          worker.perform
        end
      end
    end
  end
end
