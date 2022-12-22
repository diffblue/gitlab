# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoricalStatistics::AdjustmentService, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project) }

  around do |example|
    travel_to(Date.current) { example.run }
  end

  describe '.execute' do
    let(:project_ids) { [1, 2, 3] }
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    subject(:execute_for_project_ids) { described_class.execute(project_ids) }

    before do
      allow(described_class).to receive(:new).and_return(mock_service_object)
    end

    it 'instantiates the service object for given project ids and calls `execute` on them', :aggregate_failures do
      execute_for_project_ids

      expect(described_class).to have_received(:new).with([1, 2, 3])
      expect(mock_service_object).to have_received(:execute)
    end
  end

  describe '#execute' do
    let(:statistics) { project.vulnerability_historical_statistics.last.reload.as_json(except: [:id, :project_id, :created_at, :updated_at]) }
    let(:project_ids) { [project.id] }

    let(:expected_statistics) do
      {
        'total' => 2,
        'critical' => 1,
        'high' => 1,
        'medium' => 0,
        'low' => 0,
        'info' => 0,
        'unknown' => 0,
        'letter_grade' => 'f',
        'date' => Date.current.to_s
      }
    end

    subject(:adjust_statistics) { described_class.new(project_ids).execute }

    context 'when more than 1000 projects is provided' do
      let(:project_ids) { (1..1001).to_a }

      it 'raises error' do
        expect { adjust_statistics }.to raise_error do |error|
          expect(error.class).to eql(described_class::TooManyProjectsError)
          expect(error.message).to eql('Cannot adjust statistics for more than 1000 projects')
        end
      end
    end

    context 'when there is no vulnerability_statistic record for project' do
      it 'does not create a new record in database' do
        expect { adjust_statistics }.not_to change { Vulnerabilities::Statistic.count }
      end
    end

    context 'when there is vulnerability_statistic record for project' do
      let!(:vulnerability_statistic) { create(:vulnerability_statistic, project: project, total: 2, critical: 1, high: 1) }

      context 'when there is no vulnerability_historical_statistic record for project' do
        it 'creates a new record' do
          expect { adjust_statistics }.to change { Vulnerabilities::HistoricalStatistic.count }.by(1)
        end

        it 'sets the correct values for the record' do
          adjust_statistics

          expect(statistics).to eq(expected_statistics)
        end
      end

      context 'when there is already a vulnerability_historical_statistic record for project' do
        let!(:vulnerability_historical_statistic) { create(:vulnerability_historical_statistic, project: project) }

        it 'does not create a new record in database' do
          expect { adjust_statistics }.not_to change { Vulnerabilities::Statistic.count }
        end

        it 'sets the correct values for the record' do
          adjust_statistics

          expect(statistics).to eq(expected_statistics)
        end
      end
    end
  end
end
