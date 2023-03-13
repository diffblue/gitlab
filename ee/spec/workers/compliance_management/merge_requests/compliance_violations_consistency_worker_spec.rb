# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyWorker,
  feature_category: :compliance_management do
  describe "#perform", :clean_gitlab_redis_shared_state, :sidekiq_inline do
    subject(:worker) { described_class.new }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:project_two) { create(:project, :repository) }
    let_it_be(:two_days_ago) { 2.days.ago }
    let_it_be(:five_days_ago) { 5.days.ago }

    let_it_be(:merge_request) do
      create(:merge_request, :with_merged_metrics, source_project: project, state: :merged, target_branch: "main",
        title: "MR 1", merged_at: two_days_ago)
    end

    let_it_be(:merge_request_two) do
      create(:merge_request, :with_merged_metrics, source_project: project, state: :merged, target_branch: "main",
        title: "MR 2", merged_at: five_days_ago)
    end

    let_it_be(:violation) do
      create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request,
        title: "MR one", target_branch: "master", target_project_id: project_two.id, merged_at: 1.day.ago)
    end

    let_it_be(:violation_two) do
      create(:compliance_violation, :approved_by_committer, severity_level: :high, merge_request: merge_request_two,
        title: "MR 2", target_branch: "main", target_project_id: project.id, merged_at: five_days_ago)
    end

    it 'updates the inconsistent attributes in merge request compliance violation table' do
      expect(violation).not_to have_attributes(expected_attributes(merge_request))
      expect(violation_two).to have_attributes(expected_attributes(merge_request_two))

      worker.perform

      expect(violation.reload).to have_attributes(expected_attributes(merge_request))
      expect(violation.reload.merged_at).to be_within(0.00001.seconds).of(merge_request.merged_at)
      expect(violation_two).to have_attributes(expected_attributes(merge_request_two))
    end

    context 'when the worker is running for more than 4 minutes' do
      before do
        allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(0, 241)
      end

      it 'enqueues the worker again to process the rest of the rows' do
        expect(::MergeRequests::ComplianceViolation).to receive(:where).with('id >= ?', 0).once.and_call_original
        expect(::MergeRequests::ComplianceViolation).to receive(:where).with('id >= ?', violation.id).once
                                                                       .and_call_original
        allow(::MergeRequests::ComplianceViolation).to receive(:where).and_call_original
        expect(::ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyWorker).to receive(:perform_async)
                                                                                                  .and_call_original

        worker.perform
      end
    end

    context 'when the worker finishes processing in less than 4 minutes' do
      before do
        Gitlab::Redis::Cache.with do |redis|
          redis.set('last_processed_mr_violation_id', violation.id)
        end
      end

      it 'clears the last processed violation_id from redis cache' do
        Gitlab::Redis::Cache.with do |redis|
          expect { worker.perform }
            .to change { redis.get('last_processed_mr_violation_id') }.to(nil)
        end
      end
    end

    it_behaves_like 'an idempotent worker'
  end

  # @param [MergeRequest, MergeRequests::ComplianceViolation] model
  def expected_attributes(model)
    {
      title: model.title,
      target_branch: model.target_branch,
      target_project_id: model.target_project_id
    }
  end
end
