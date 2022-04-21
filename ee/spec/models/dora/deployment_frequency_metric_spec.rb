# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::DeploymentFrequencyMetric do
  describe '#data_queries' do
    subject { described_class.new(environment, date.to_date).data_queries }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:date) { 1.day.ago }

    around do |example|
      freeze_time { example.run }
    end

    it 'returns number of finished successful deployments' do
      # Matching deployments
      create(:deployment, :success, environment: environment, finished_at: date.beginning_of_day)
      create(:deployment, :success, environment: environment, finished_at: date)
      create(:deployment, :success, environment: environment, finished_at: date.end_of_day)

      # Not matching deployments
      create(:deployment, :failed, environment: environment, finished_at: date) # failed deployment
      create(:deployment, :success, environment: environment, finished_at: date - 1.day) # different day
      create(:deployment, :success, environment: environment, finished_at: date + 1.day) # different day
      create(:deployment, :success, finished_at: date + 1.day) # different environment

      expect(subject.size).to eq 1
      expect(Deployment.connection.execute(subject[:deployment_frequency]).first['count']).to be 3
    end
  end
end
