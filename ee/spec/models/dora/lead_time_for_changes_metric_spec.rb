# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::LeadTimeForChangesMetric do
  describe '#data_queries' do
    subject { described_class.new(environment, date.to_date).data_queries }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:date) { 1.day.ago }

    around do |example|
      freeze_time { example.run }
    end

    it 'returns median of time between merge and deployment' do
      create(:merge_request, :with_merged_metrics, project: project, merged_at: date - 1.day)

      merge_requests = [
        create(:merge_request, :with_merged_metrics, project: project, merged_at: date - 1.day),
        create(:merge_request, :with_merged_metrics, project: project, merged_at: date - 2.days),
        create(:merge_request, :with_merged_metrics, project: project, merged_at: date - 5.days)
      ]

      # Deployment finished on the date
      create(:deployment, :success, environment: environment, finished_at: date, merge_requests: merge_requests)

      expect(subject.size).to eq 1
      expect(Deployment.connection.execute(subject[:lead_time_for_changes_in_seconds]).first['percentile_cont']).to eql 2.days.to_f
    end
  end
end
