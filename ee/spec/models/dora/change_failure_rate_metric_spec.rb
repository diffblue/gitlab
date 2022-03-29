# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::ChangeFailureRateMetric do
  describe '#data_queries' do
    subject { described_class.new(environment, date.to_date).data_queries }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, :production, project: project) }
    let_it_be(:date) { 1.day.ago }

    around do |example|
      freeze_time { example.run }
    end

    before_all do
      create(:incident, project: project, created_at: date.beginning_of_day)
      create(:incident, project: project, created_at: date.beginning_of_day + 1.hour)
      create(:incident, project: project, created_at: date.end_of_day)

      # Issues which shouldn't be included in calculation
      create(:issue, project: project, created_at: date) # not an incident
      create(:incident, created_at: date) # different project
      create(:incident, project: project, created_at: date - 1.year) # different date
      create(:incident, project: project, created_at: date + 1.year) # different date
    end

    context 'for production environment' do
      it 'returns number of incidents opened at given date' do
        expect(subject.size).to eq 2
        expect(Issue.connection.execute(subject[:incidents_count]).first['count']).to be 3
      end

      it 'inherits data queries from DeploymentFrequency metric' do
        allow_next_instance_of(Dora::DeploymentFrequencyMetric) do |instance|
          allow(instance).to receive(:data_queries).and_return({ deployment_frequency: 12345 } )
        end

        expect(subject[:deployment_frequency]).to eq 12345
      end
    end

    context 'for non-production environment' do
      let_it_be(:environment) { create(:environment, project: project) }

      it 'returns no queries' do
        expect(subject.size).to eq 0
      end
    end
  end
end
