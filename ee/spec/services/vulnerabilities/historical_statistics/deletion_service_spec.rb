# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::HistoricalStatistics::DeletionService, feature_category: :vulnerability_management do
  describe '.execute' do
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    before do
      allow(described_class).to receive(:new).and_return(mock_service_object)
    end

    it 'instantiates the service object and calls `execute`' do
      described_class.execute

      expect(mock_service_object).to have_received(:execute)
    end
  end

  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }

    subject(:delete_historical_statistics) { described_class.new.execute }

    before do
      create(:vulnerability_historical_statistic, project: project, date: 10.days.ago)
      create(:vulnerability_historical_statistic, project: project, date: 20.days.ago)
      create(:vulnerability_historical_statistic, project: other_project, date: 15.days.ago)
      create(:vulnerability_historical_statistic, project: other_project, date: 25.days.ago)
    end

    context 'when there is no historical statistics older than 365 days' do
      it 'does not delete historical statistics' do
        expect { delete_historical_statistics }.not_to change { Vulnerabilities::HistoricalStatistic.count }
      end
    end

    context 'when there is a historical statistic entry that was created 364 days ago' do
      before do
        create(:vulnerability_historical_statistic, project: project, date: 364.days.ago)
        create(:vulnerability_historical_statistic, project: other_project, date: 364.days.ago)
      end

      it 'does not delete historical statistics' do
        expect { delete_historical_statistics }.not_to change { Vulnerabilities::HistoricalStatistic.count }
      end

      context 'and there are more than one entries that are older than 365 days' do
        before do
          create(:vulnerability_historical_statistic, project: project, date: 366.days.ago)
          create(:vulnerability_historical_statistic, project: project, date: 367.days.ago)
          create(:vulnerability_historical_statistic, project: project, date: 368.days.ago)
          create(:vulnerability_historical_statistic, project: other_project, date: 366.days.ago)
          create(:vulnerability_historical_statistic, project: other_project, date: 367.days.ago)
          create(:vulnerability_historical_statistic, project: other_project, date: 368.days.ago)
        end

        it 'deletes historical statistics older than 365 days', :aggregate_failures do
          expect { delete_historical_statistics }.to change { Vulnerabilities::HistoricalStatistic.count }.by(-6)
          expect(Vulnerabilities::HistoricalStatistic.pluck(:date)).to all(be >= 365.days.ago.to_date)
        end
      end
    end
  end
end
