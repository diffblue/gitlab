# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::TimeToRestoreServiceMetric do
  describe '#data_queries' do
    subject { described_class.new(environment, date.to_date).data_queries }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, :production, project: project) }
    let_it_be(:date) { 1.day.ago }

    around do |example|
      freeze_time { example.run }
    end

    before_all do
      create(:incident, :closed, project: project, created_at: date - 7.days, closed_at: date)
      create(:incident, :closed, project: project, created_at: date - 5.days, closed_at: date)
      create(:incident, :closed, project: project, created_at: date - 3.days, closed_at: date)
      create(:incident, :closed, project: project, created_at: date - 1.day, closed_at: date)

      # Issues which shouldn't be included in calculation
      create(:issue, :closed, project: project, created_at: date - 1.year, closed_at: date) # not an incident
      create(:incident, project: project, created_at: date - 1.year) # not closed yet
      create(:incident, :closed, created_at: date - 1.year, closed_at: date) # different project
      create(:incident, :closed, project: project, created_at: date - 1.year, closed_at: date + 1.day) # different date
    end

    context 'for production environment' do
      it 'returns median of incidents duration closed at given date' do
        expect(subject.size).to eq 1
        expect(Issue.connection.execute(subject[:time_to_restore_service_in_seconds]).first['percentile_cont']).to eql 4.days.to_f
      end
    end

    context 'for non-production environment' do
      let_it_be(:environment) { create(:environment, project: project) }

      it 'does not calculate time_to_restore_service daily metric' do
        expect(subject.size).to eq 0
      end
    end
  end
end
