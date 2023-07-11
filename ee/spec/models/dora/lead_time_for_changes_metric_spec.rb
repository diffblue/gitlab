# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::LeadTimeForChangesMetric do
  describe '#data_queries' do
    subject(:data_queries) { described_class.new(environment, date.to_date).data_queries }

    let(:query_result) { Deployment.connection.execute(data_queries[:lead_time_for_changes_in_seconds]).first['percentile_cont'] }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }
    let_it_be(:date) { 1.day.ago }

    before_all do
      create(:merge_request, :with_merged_metrics, project: project, target_branch: 'main', merged_at: date - 1.day)

      merge_requests = [
        create(:merge_request, :with_merged_metrics, project: project, target_branch: 'main', merged_at: date - 1.day),
        create(:merge_request, :with_merged_metrics, project: project, target_branch: 'staging', merged_at: date - 5.days),
        create(:merge_request, :with_merged_metrics, project: project, target_branch: 'production', merged_at: date - 7.days)
      ]

      # Deployment finished on the date
      create(:deployment, :success, environment: environment, finished_at: date, merge_requests: merge_requests)
    end

    around do |example|
      freeze_time { example.run }
    end

    context 'with dora_configuration disabled' do
      before do
        stub_feature_flags(dora_configuration: false)
      end

      it 'returns median of time between merge and deployment' do
        expect(query_result).to eql 5.days.to_f
      end
    end

    context 'with dora_configuration enabled' do
      context 'without configuration object' do
        it 'returns median of time between merge and deployment' do
          expect(query_result).to eql 5.days.to_f
        end
      end

      context 'with empty branches configuration' do
        before do
          create :dora_configuration, project: project, branches_for_lead_time_for_changes: []
        end

        it 'returns median of time between merge and deployment' do
          expect(query_result).to eql 5.days.to_f
        end
      end

      context 'with filled branches configuration' do
        before do
          create :dora_configuration, project: project, branches_for_lead_time_for_changes: %w[main staging]
        end

        it 'returns median of time between merge and deployment for MRs with target branch from configuration allowlist' do
          expect(query_result).to eql 3.days.to_f
        end
      end
    end
  end
end
