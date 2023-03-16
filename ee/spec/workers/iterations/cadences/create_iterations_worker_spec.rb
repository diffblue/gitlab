# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iterations::Cadences::CreateIterationsWorker, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:start_date) { 3.weeks.from_now }
  let_it_be(:cadence) { create(:iterations_cadence, group: group, automatic: true, start_date: start_date, duration_in_weeks: 1, iterations_in_advance: 2) }

  let(:mock_service) { double('mock_service', execute: ::ServiceResponse.success) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when passing in nil cadence id' do
      it 'exits early' do
        expect(Iterations::Cadences::CreateIterationsInAdvanceService).not_to receive(:new)

        worker.perform(nil)
      end
    end

    context 'when passing in non-existent cadence id' do
      it 'exits early' do
        expect(Iterations::Cadences::CreateIterationsInAdvanceService).not_to receive(:new)

        worker.perform(non_existing_record_id)
      end
    end

    context 'when passing existent cadence id' do
      let(:mock_success_service) { double('mock_service', execute: ::ServiceResponse.success) }
      let(:mock_error_service) { double('mock_service', execute: ::ServiceResponse.error(message: 'some error')) }

      it 'invokes CreateIterationsInAdvanceService' do
        expect(Iterations::Cadences::CreateIterationsInAdvanceService).to receive(:new).with(kind_of(User), kind_of(Iterations::Cadence)).and_return(mock_success_service)
        expect(worker).not_to receive(:log_error)

        worker.perform(cadence.id)
      end

      context 'when CreateIterationsInAdvanceService returns error' do
        it 'logs error' do
          allow(Iterations::Cadences::CreateIterationsInAdvanceService).to receive(:new).and_return(mock_error_service)
          allow(mock_service).to receive(:execute)
          expect(worker).to receive(:log_error)

          worker.perform(cadence.id)
        end
      end
    end
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { [cadence.id] }
  end
end
