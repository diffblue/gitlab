# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::GroupLevel, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:from_date) { 10.days.ago }
  let_it_be(:user) { create(:user) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  around do |example|
    freeze_time { example.run }
  end

  subject { described_class.new(group: group, options: { from: from_date, current_user: user }) }

  before do
    # Cannot set the owner directly when calling `create(:group)`
    # See spec/factories/groups.rb#after(:create)
    group.add_owner(user)
  end

  describe '#summary' do
    before do
      stub_licensed_features(dora4_analytics: true)

      create_cycle(user, project, issue, mr, milestone, pipeline)
      deploy_master(user, project)

      environment = project.environments.production.first
      ::Dora::DailyMetrics::RefreshWorker.new.perform(environment.id, pipeline.created_at.to_date.to_s)
    end

    it 'returns medians for each stage for a specific group', :sidekiq_inline do
      expect(subject.summary.map { |summary| summary[:value] }).to eq(['1', '1', '0.1'])
    end

    context 'when the fix_dora_deployment_frequency_calculation is off' do
      before do
        stub_feature_flags(fix_dora_deployment_frequency_calculation: false)
      end

      it 'returns medians for each stage for a specific group', :sidekiq_inline do
        expect(subject.summary.map { |summary| summary[:value] }).to eq(['1', '1', '0.1'])
      end
    end
  end

  describe '#time_summary' do
    let(:issue) { create(:issue, project: project) }

    before do
      # lead_time: 1 day, cycle_time: 2 days

      issue.update!(created_at: 5.days.ago)

      issue.metrics.update!(first_mentioned_in_commit_at: 4.days.ago)

      issue.update!(closed_at: 3.days.ago)
    end

    it 'returns medians for lead time and cycle type' do
      expect(subject.time_summary.map { |summary| summary[:value] }).to contain_exactly('1.0', '2.0')
    end
  end
end
