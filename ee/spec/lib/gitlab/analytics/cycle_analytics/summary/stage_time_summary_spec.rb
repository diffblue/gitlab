# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::StageTimeSummary, feature_category: :devops_reports do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:project_2) { create(:project, :repository, namespace: group) }
  let_it_be(:project_3) { create(:project, :repository, namespace: group) }
  let_it_be(:user) { create(:user) }

  let(:from) { 1.day.ago }
  let(:to) { nil }
  let(:options) { { from: from, to: to, current_user: user } }
  let(:stage) { Analytics::CycleAnalytics::Stage.new(namespace: group) }

  subject do
    described_class.new(stage, options: options).data
  end

  around do |example|
    freeze_time { example.run }
  end

  before do
    group.add_owner(user)
  end

  context 'when the use_aggregated_data_collector option is given' do
    context 'when aggregated data is not available yet' do
      it 'shows no value' do
        expect_values(lead_time: '-', cycle_time: '-', time_to_merge: '-')
      end
    end

    context 'when aggregated data is present' do
      before do
        issue = create(:closed_issue, project: project, created_at: 1.day.ago, closed_at: Time.current)
        issue.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)

        merge_request = create(:merge_request, :merged, created_at: 5.days.ago, project: project)
        merge_request.metrics.update!(merged_at: 1.day.ago)

        options[:use_aggregated_data_collector] = true
        stub_licensed_features(cycle_analytics_for_groups: true)
        Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: model).execute
      end

      context 'when only Issue model is specified' do
        let(:model) { Issue }

        it 'loads the lead time, cycle time and time to merge' do
          # this only loads Issue models, so Time to Merge is not filled in.
          expect_values(lead_time: '1.0', cycle_time: '2.0', time_to_merge: '-')
        end
      end

      context 'when only MR model is specified' do
        let(:model) { MergeRequest }

        it 'shows time to merge' do
          # this only shows MergeRequest models, so the first two are not filled in.
          expect_values(lead_time: '-', cycle_time: '-', time_to_merge: '4.0')
        end
      end

      context 'when some other model is specified' do
        let(:model) { Epic }

        it 'shows none of the values' do
          expect_values(lead_time: '-', cycle_time: '-', time_to_merge: '-')
        end
      end
    end

    def expect_values(lead_time:, cycle_time:, time_to_merge:)
      expect(subject.as_json).to contain_exactly(
        a_hash_including({
          "identifier" => 'lead_time',
          "value" => lead_time
        }),
        a_hash_including({
          "identifier" => 'cycle_time',
          "value" => cycle_time
        }),
        a_hash_including({
          "identifier" => 'time_to_merge',
          "value" => time_to_merge
        })
      )
    end
  end

  describe '#lead_time' do
    let(:lead_time) do
      subject.find { |result| result[:identifier] == :lead_time }
    end

    describe 'issuable filter parameters' do
      let_it_be(:label) { create(:group_label, group: group) }

      before do
        create(:closed_issue, project: project, created_at: 1.day.ago, closed_at: Time.zone.now, author: user, labels: [label])
      end

      context 'when `author_username` is given' do
        before do
          options[:author_username] = user.username
        end

        it 'returns the correct lead time' do
          expect(lead_time[:value]).to eq('1.0')
        end
      end

      context 'when unknown `author_username` is given' do
        before do
          options[:author_username] = 'unknown_user'
        end

        it 'returns `-`' do
          expect(lead_time[:value]).to eq('-')
        end
      end

      context 'when `label_name` is given' do
        before do
          options[:label_name] = [label.name]
        end

        it 'returns the correct lead time' do
          expect(lead_time[:value]).to eq('1.0')
        end
      end

      context 'when unknown `label_name` is given' do
        before do
          options[:label_name] = ['unknown_label']
        end

        it 'returns `-`' do
          expect(lead_time[:value]).to eq('-')
        end
      end
    end

    context 'with `from` date' do
      let(:from) { 6.days.ago }

      before do
        create(:closed_issue, project: project, created_at: 1.day.ago, closed_at: Time.zone.now)
        create(:closed_issue, project: project, created_at: 2.days.ago, closed_at: Time.zone.now)
        create(:closed_issue, project: project_2, created_at: 4.days.ago, closed_at: Time.zone.now)
      end

      it 'finds the lead time of issues created after it' do
        expect(lead_time[:value]).to eq('2.0')
      end

      context 'with subgroups' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project_3) { create(:project, namespace: subgroup) }

        before do
          create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now, project: project_3)
          create(:closed_issue, created_at: 5.days.ago, closed_at: Time.zone.now, project: project_3)
        end

        it 'finds the lead time of issues from them' do
          expect(lead_time[:value]).to eq('3.0')
        end
      end

      context 'with projects specified in options' do
        before do
          create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now, project: create(:project, namespace: group))
        end

        subject { described_class.new(stage, options: { from: from, current_user: user, projects: [project.id, project_2.id] }).data }

        it 'finds the lead time of issues from those projects' do
          # Median of 1, 2, 4, not including new issue
          expect(lead_time[:value]).to eq('2.0')
        end
      end

      context 'when `from` and `to` parameters are provided' do
        let(:from) { 3.days.ago }
        let(:to) { Time.zone.now }

        it 'finds the lead time of issues from 3 days ago' do
          expect(lead_time[:value]).to eq('1.5')
        end
      end
    end

    context 'with other projects' do
      let(:from) { 4.days.ago }

      before do
        create(:closed_issue, created_at: 1.day.ago, closed_at: Time.zone.now, project: create(:project, namespace: create(:group)))
        create(:closed_issue, created_at: 2.days.ago, closed_at: Time.zone.now,  project: project)
        create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now,  project: project_2)
      end

      it 'does not find the lead time of issues from them' do
        # Median of  2, 3, not including first issue
        expect(lead_time[:value]).to eq('2.5')
      end
    end
  end

  describe '#cycle_time' do
    let(:created_at) { 6.days.ago }
    let(:cycle_time) do
      subject.find do |result|
        result[:identifier] == :cycle_time
      end
    end

    context 'with `from` date' do
      let(:from) { 7.days.ago }

      before do
        issue_1 = create(:closed_issue, project: project, closed_at: Time.zone.now, created_at: created_at)
        issue_2 = create(:closed_issue, project: project, closed_at: Time.zone.now, created_at: created_at)
        issue_3 = create(:closed_issue, project: project_2, closed_at: Time.zone.now, created_at: created_at)

        issue_1.metrics.update!(first_mentioned_in_commit_at: 1.day.ago)
        issue_2.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
        issue_3.metrics.update!(first_mentioned_in_commit_at: 4.days.ago)
      end

      it 'finds the cycle time of issues created after it' do
        expect(cycle_time[:value]).to eq('2.0')
      end

      context 'with subgroups' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project_3) { create(:project, namespace: subgroup) }

        before do
          issue_4 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: project_3)
          issue_5 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: project_3)

          issue_4.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
          issue_5.metrics.update!(first_mentioned_in_commit_at: 5.days.ago)
        end

        it 'finds the cycle time of issues from them' do
          expect(cycle_time[:value]).to eq('3.0')
        end
      end

      context 'with projects specified in options' do
        before do
          issue_4 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: create(:project, namespace: group))
          issue_4.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
        end

        subject { described_class.new(stage, options: { from: from, current_user: user, projects: [project.id, project_2.id] }).data }

        it 'finds the cycle time of issues from those projects' do
          # Median of 1, 2, 4, not including new issue
          expect(cycle_time[:value]).to eq('2.0')
        end
      end

      context 'when `from` and `to` parameters are provided' do
        let(:from) { 5.days.ago }
        let(:to) { 2.days.ago }
        let(:created_at) { from }

        it 'finds the cycle time of issues created between `from` and `to`' do
          # Median of 1, 2, 4
          expect(cycle_time[:value]).to eq('2.0')
        end
      end
    end

    context 'with other projects' do
      let(:from) { 4.days.ago }
      let(:created_at) { from }

      before do
        issue_1 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: create(:project, namespace: create(:group)))
        issue_2 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now,  project: project)
        issue_3 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now,  project: project_2)

        issue_1.metrics.update!(first_mentioned_in_commit_at: 1.day.ago)
        issue_2.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
        issue_3.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
      end

      it 'does not find the cycle time of issues from them' do
        # Median of  2, 3, not including first issue
        expect(cycle_time[:value]).to eq('2.5')
      end
    end
  end

  describe '#time_to_merge' do
    let(:created_at) { 6.days.ago }
    let(:time_to_merge) do
      subject.find { |result| result[:identifier] == :time_to_merge }
    end

    context 'with `from` date' do
      let(:from) { 7.days.ago }

      before do
        mr1 = create(:merge_request, :merged, project: project, created_at: created_at)
        mr2 = create(:merge_request, :merged, project: project, created_at: created_at)
        mr3 = create(:merge_request, :merged, project: project_2, created_at: created_at)

        mr1.metrics.update!(merged_at: 1.day.ago)
        mr2.metrics.update!(merged_at: 2.days.ago)
        mr3.metrics.update!(merged_at: 4.days.ago)
      end

      it 'finds the time to merge of MRs created after it' do
        expect(time_to_merge).to include({ value: '4.0', title: "Time to Merge", unit: "days" })
      end

      context 'with subgroups' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let_it_be(:project_3) { create(:project, namespace: subgroup) }

        before do
          mr4 = create(:merge_request, :merged, created_at: created_at, project: project_3)
          mr5 = create(:merge_request, :merged, created_at: created_at, project: project_3)

          mr4.metrics.update!(merged_at: 3.days.ago)
          mr5.metrics.update!(merged_at: 5.days.ago)
        end

        it 'finds the time to merge of MRs from them' do
          expect(time_to_merge).to include({ value: '3.0', title: "Time to Merge", unit: "days" })
        end
      end

      context 'with projects specified in options' do
        before do
          mr4 = create(:merge_request, :merged, created_at: created_at, project: create(:project, namespace: group))
          mr4.metrics.update!(merged_at: 3.days.ago)
        end

        subject { described_class.new(stage, options: { from: from, current_user: user, projects: [project.id, project_2.id] }).data }

        it 'finds the time to merge of MRs from those projects' do
          # Median of 1, 2, 4, not including new issue
          expect(time_to_merge).to include({ value: '4.0', title: "Time to Merge", unit: "days" })
        end
      end

      context 'when `from` and `to` parameters are provided' do
        let(:from) { 5.days.ago }
        let(:to) { 2.days.ago }
        let(:created_at) { from }

        it 'finds the time to merge of MRs created between `from` and `to`' do
          expect(time_to_merge).to include({ value: '3.0', title: "Time to Merge", unit: "days" })
        end
      end
    end

    context 'with other projects' do
      let(:from) { 4.days.ago }
      let(:created_at) { from }

      before do
        mr1 = create(:merge_request, :merged, created_at: created_at, project: create(:project, namespace: create(:group)))
        mr2 = create(:merge_request, :merged, created_at: created_at, project: project)
        mr3 = create(:merge_request, :merged, created_at: created_at, project: project_2)

        mr1.metrics.update!(merged_at: 1.day.ago)
        mr2.metrics.update!(merged_at: 2.days.ago)
        mr3.metrics.update!(merged_at: 3.days.ago)
      end

      it 'does not find the time to merge of MRs from them' do
        # Median of 2, 3, not including first MR
        expect(time_to_merge).to include({ value: '1.5', title: "Time to Merge", unit: "days" })
      end
    end
  end

  describe 'dora4 metrics' do
    let(:lead_time_for_changes) { subject.find { |result| result[:identifier] == :lead_time_for_changes } }
    let(:time_to_restore_service) { subject.find { |result| result[:identifier] == :time_to_restore_service } }
    let(:change_failure_rate) { subject.find { |result| result[:identifier] == :change_failure_rate } }

    before do
      stub_licensed_features(dora4_analytics: true)
    end

    context 'when no data available' do
      it 'returns no data' do
        expect(lead_time_for_changes[:title]).to eq(s_('CycleAnalytics|Lead Time for Changes'))
        expect(lead_time_for_changes[:value]).to eq('-')
        expect(time_to_restore_service[:title]).to eq(s_('CycleAnalytics|Time to Restore Service'))
        expect(time_to_restore_service[:value]).to eq('-')
        expect(change_failure_rate[:title]).to eq(s_('CycleAnalytics|Change Failure Rate'))
        expect(change_failure_rate[:value]).to eq('0')
      end
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(dora4_analytics: false)
      end

      it 'does not return any dora4 metrics' do
        expect(subject.size).to eq 3
      end
    end

    context 'with present data' do
      let_it_be(:environment_1) { create(:environment, :production, project: project) }
      let_it_be(:environment_2) { create(:environment, :production, project: project_2) }
      let_it_be(:environment_3) { create(:environment, :production, project: project_3) }

      before do
        create(:dora_daily_metrics,
               environment: environment_1,
               date: from,
               lead_time_for_changes_in_seconds: 2.hours,
               time_to_restore_service_in_seconds: 6.hours,
               incidents_count: 1,
               deployment_frequency: 2)

        create(:dora_daily_metrics,
               environment: environment_2,
               date: from,
               lead_time_for_changes_in_seconds: 4.hours, # median
               time_to_restore_service_in_seconds: 8.hours, # median
               incidents_count: 3,
               deployment_frequency: 4)

        create(:dora_daily_metrics,
               environment: environment_3,
               date: from,
               lead_time_for_changes_in_seconds: 7.hours,
               time_to_restore_service_in_seconds: 9.hours,
               incidents_count: 5,
               deployment_frequency: 6)
      end

      it 'returns 3 metrics' do
        expect(lead_time_for_changes[:value]).to eq((5.0 / 24).round(1).to_s) # median
        expect(time_to_restore_service[:value]).to eq((8.0 / 24).round(1).to_s) # median
        expect(change_failure_rate[:value]).to eq((9.0 * 100 / 12).round(1).to_s) # rate
      end

      context 'when project ids filter is given' do
        before do
          options[:projects] = [project]
        end

        it 'filters metrics subset by project' do
          expect(lead_time_for_changes[:value]).to eq((2.0 / 24).round(1).to_s)
          expect(time_to_restore_service[:value]).to eq((6.0 / 24).round(1).to_s)
          expect(change_failure_rate[:value]).to eq((1.0 * 100 / 2).round(1).to_s)
        end
      end
    end
  end
end
