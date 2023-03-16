# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::DailyMetrics::RefreshWorker, feature_category: :continuous_delivery do
  let_it_be(:environment) { create(:environment) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(environment_id, date.to_s) }

    let(:environment_id) { environment.id }
    let(:date) { Time.current.to_date }

    it 'refreshes the DORA metrics on the environment and date' do
      expect(::Dora::DailyMetrics).to receive(:refresh!).with(environment, date)

      subject
    end

    context 'when the date is not parsable' do
      let(:date) { 'abc' }

      it 'raises an error' do
        expect { subject }.to raise_error(Date::Error)
      end
    end

    context 'when an environment does not exist' do
      let(:environment_id) { non_existing_record_id }

      it 'does not refresh' do
        expect(::Dora::DailyMetrics).not_to receive(:refresh!)

        subject
      end
    end
  end
end
