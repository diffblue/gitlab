# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::DataCollector, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }

  let(:current_time) { Time.zone.local(2019, 6, 1) }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  around do |example|
    travel_to(current_time)
    example.run
    travel_back
  end

  def round_to_days(seconds)
    seconds.fdiv(1.day.to_i).round
  end

  def aggregate_vsa_data(group)
    Analytics::CycleAnalytics::DataLoaderService.new(
      group: group,
      model: Issue
    ).execute

    Analytics::CycleAnalytics::DataLoaderService.new(
      group: group,
      model: MergeRequest
    ).execute
  end

  # Setting up test data for a stage depends on the `start_event_identifier` and
  # `end_event_identifier` attributes. Since stages can be customized, the test
  # uses two methods for the data preparaton: `create_data_for_start_event` and
  # `create_data_for_end_event`. For each stage we create 3 records with a fixed
  # durations (10, 5, 15 days) in order to easily generalize the test cases.
  shared_examples 'custom Value Stream Analytics Stage' do
    let(:params) { { from: Time.zone.local(2019), to: Time.zone.local(2020), current_user: user } }
    let(:data_collector) { described_class.new(stage: stage, params: params) }
    let(:aggregated_data_collector) { described_class.new(stage: stage, params: params.merge(use_aggregated_data_collector: true)) }

    let_it_be(:resource_1_end_time) { Time.zone.local(2019, 3, 15) }
    let_it_be(:resource_2_end_time) { Time.zone.local(2019, 3, 10) }
    let_it_be(:resource_3_end_time) { Time.zone.local(2019, 3, 20) }

    let_it_be(:resource1) do
      # takes 10 days
      resource = travel_to(Time.zone.local(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_1_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:resource2) do
      # takes 5 days
      resource = travel_to(Time.zone.local(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_2_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:resource3) do
      # takes 15 days
      resource = travel_to(Time.zone.local(2019, 3, 5)) do
        create_data_for_start_event(self)
      end

      travel_to(resource_3_end_time) do
        create_data_for_end_event(resource, self)
      end

      resource
    end

    let_it_be(:unfinished_resource_1_start_time) { Time.zone.local(2019, 3, 5) }
    let_it_be(:unfinished_resource_2_start_time) { Time.zone.local(2019, 5, 10) }

    let_it_be(:unfinished_resource_1) do
      travel_to(unfinished_resource_1_start_time) do
        create_data_for_start_event(self)
      end
    end

    let_it_be(:unfinished_resource_2) do
      travel_to(unfinished_resource_2_start_time) do
        create_data_for_start_event(self)
      end
    end

    it 'loads serialized records' do
      items = data_collector.serialized_records
      expect(items.size).to eq(3)

      expect(aggregated_data_collector.serialized_records.size).to eq(3) if aggregated_data_collector_enabled
    end

    context 'when sorting by duration' do
      before do
        params[:sort] = :duration
        params[:direction] = :desc
      end

      it 'returns serialized records sorted by duration DESC' do
        expected_ordered_iids = [resource3.iid, resource1.iid, resource2.iid]

        iids = data_collector.serialized_records.map { |record| record[:iid].to_i }
        expect(iids).to eq(expected_ordered_iids)

        if aggregated_data_collector_enabled
          iids = aggregated_data_collector.serialized_records.map { |record| record[:iid].to_i }
          expect(iids).to eq(expected_ordered_iids)
        end
      end
    end

    it 'calculates median' do
      expect(round_to_days(data_collector.median.seconds)).to eq(10)
      expect(round_to_days(aggregated_data_collector.median.seconds)).to eq(10) if aggregated_data_collector_enabled
    end

    describe '#duration_chart_average_data' do
      subject { data_collector.duration_chart_average_data }

      it 'loads data ordered by event time' do
        data = subject.map { |item| [item.date, round_to_days(item.average_duration_in_seconds)] }

        expect(Hash[data]).to eq({
          resource_1_end_time.utc.to_date => 10,
          resource_2_end_time.utc.to_date => 5,
          resource_3_end_time.utc.to_date => 15
        })

        if aggregated_data_collector_enabled
          data = aggregated_data_collector.duration_chart_average_data.map { |item| [item.date, round_to_days(item.average_duration_in_seconds)] }
          expect(Hash[data]).to eq({
            resource_1_end_time.utc.to_date => 10,
            resource_2_end_time.utc.to_date => 5,
            resource_3_end_time.utc.to_date => 15
          })
        end
      end
    end

    describe '#count' do
      subject(:count) { data_collector.count }

      it 'returns limited count' do
        expect(data_collector.count).to eq(3)
        expect(aggregated_data_collector.count).to eq(3) if aggregated_data_collector_enabled
      end
    end

    context 'when filtering in progress items' do
      before do
        params[:end_event_filter] = :in_progress
      end

      describe '#count' do
        it 'returns limited count' do
          expect(data_collector.count).to eq(2)
          expect(aggregated_data_collector.count).to eq(2) if aggregated_data_collector_enabled
        end
      end

      it 'calculates median' do
        duration_1 = current_time - unfinished_resource_1_start_time
        duration_2 = current_time - unfinished_resource_2_start_time

        expected_median = (duration_1 + duration_2).fdiv(2)

        expect(round_to_days(data_collector.median.seconds)).to eq(round_to_days(expected_median))
        expect(round_to_days(aggregated_data_collector.median.seconds)).to eq(round_to_days(expected_median)) if aggregated_data_collector_enabled
      end

      it 'loads serialized records' do
        items = data_collector.serialized_records
        expect(items.size).to eq(2)
      end
    end
  end

  shared_examples 'test various start and end event combinations' do
    context 'when `Issue` based stage is given' do
      context 'between issue creation time and issue first mentioned in commit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_mentioned_in_commit }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(issue, example_class)
          issue.metrics.update!(first_mentioned_in_commit_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and closing time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_closed }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.close!
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue first mentioned in commit and first associated with milestone time' do
        let(:start_event_identifier) { :issue_first_mentioned_in_commit }
        let(:end_event_identifier) { :issue_first_associated_with_milestone }

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)
          issue.metrics.update!(first_mentioned_in_commit_at: Time.current)
          issue
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_associated_with_milestone_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and first added to board time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_added_to_board }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(first_added_to_board_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue creation time and last edit time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_last_edited }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue label added time and label removed time' do
        let(:start_event_identifier) { :issue_label_added }
        let(:end_event_identifier) { :issue_label_removed }
        let(:start_event_label) { label }
        let(:end_event_label) { label }

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)

          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              container: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end

          issue
        end

        def create_data_for_end_event(resource, example_class)
          Issues::UpdateService.new(
            container: example_class.project,
            current_user: user,
            params: { label_ids: [] }
          ).execute(resource)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue label added time and another issue label added time' do
        let(:start_event_identifier) { :issue_label_added }
        let(:end_event_identifier) { :issue_label_added }
        let(:start_event_label) { label }
        let(:end_event_label) { other_label }

        def create_data_for_start_event(example_class)
          issue = create(:issue, :opened, project: example_class.project)

          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              container: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end

          issue
        end

        def create_data_for_end_event(issue, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              container: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id, example_class.other_label.id] }
            ).execute(issue)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage' do
          context 'when filtering for two labels' do
            let(:params) do
              {
                from: Time.zone.local(2019),
                to: Time.zone.local(2020),
                current_user: user,
                label_name: [label.name, other_label.name]
              }
            end

            subject { described_class.new(stage: stage, params: params) }

            it 'does not raise query syntax error' do
              expect { subject.records_fetcher.serialized_records }.not_to raise_error
            end
          end
        end
      end

      context 'between issue creation time and issue label added time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_label_added }
        let(:end_event_label) { label }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(issue, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              container: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue first assigned at and issue closed time' do
        let(:start_event_identifier) { :issue_first_assigned_at }
        let(:end_event_identifier) { :issue_closed }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project).tap do |issue|
            create(:issue_assignment_event, issue: issue)
          end
        end

        def create_data_for_end_event(issue, _example_class)
          issue.close!
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue first assigned at and issue label added time' do
        let(:start_event_identifier) { :issue_first_assigned_at }
        let(:end_event_identifier) { :issue_label_added }
        let(:end_event_label) { label }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project).tap do |issue|
            create(:issue_assignment_event, issue: issue)
          end
        end

        def create_data_for_end_event(issue, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            Issues::UpdateService.new(
              container: example_class.project,
              current_user: user,
              params: { label_ids: [example_class.label.id] }
            ).execute(issue)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between issue created and issue first assigned time' do
        let(:start_event_identifier) { :issue_created }
        let(:end_event_identifier) { :issue_first_assigned_at }

        def create_data_for_start_event(example_class)
          create(:issue, :opened, project: example_class.project)
        end

        def create_data_for_end_event(issue, _example_class)
          create(:issue_assignment_event, issue: issue)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end
    end

    context 'when `MergeRequest` based stage is given' do
      context 'between merge request creation time and merged at time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_merged }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project)
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(merged_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request merrged time and first deployed to production at time' do
        let(:start_event_identifier) { :merge_request_merged }
        let(:end_event_identifier) { :merge_request_first_deployed_to_production }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(merged_at: Time.current)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(first_deployed_to_production_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between first commit at and merge request merged time' do
        let(:start_event_identifier) { :merge_request_first_commit_at }
        let(:end_event_identifier) { :merge_request_merged }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(first_commit_at: Time.current)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(merged_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request build started time and build finished time' do
        let(:start_event_identifier) { :merge_request_last_build_started }
        let(:end_event_identifier) { :merge_request_last_build_finished }

        def create_data_for_start_event(example_class)
          create(:merge_request, :unique_branches, :opened, source_project: example_class.project).tap do |mr|
            mr.metrics.update!(latest_build_started_at: Time.current)
          end
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(latest_build_finished_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request creation time and close time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_closed }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.metrics.update!(latest_closed_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request creation time and last edit time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_last_edited }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(resource, example_class)
          resource.update!(last_edited_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request label added time and label removed time' do
        let(:start_event_identifier) { :merge_request_label_added }
        let(:end_event_identifier) { :merge_request_label_removed }
        let(:start_event_label) { label }
        let(:end_event_label) { label }

        def create_data_for_start_event(example_class)
          mr = create(:merge_request, source_project: example_class.project, allow_broken: true)

          Sidekiq::Worker.skipping_transaction_check do
            MergeRequests::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [label.id] }
            ).execute(mr)
          end

          mr
        end

        def create_data_for_end_event(mr, example_class)
          Sidekiq::Worker.skipping_transaction_check do
            MergeRequests::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [] }
            ).execute(mr)
          end
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between merge request label added time and MR merged time' do
        let(:start_event_identifier) { :merge_request_label_added }
        let(:end_event_identifier) { :merge_request_merged }
        let(:start_event_label) { label }

        def create_data_for_start_event(example_class)
          mr = create(:merge_request, source_project: example_class.project, allow_broken: true)

          Sidekiq::Worker.skipping_transaction_check do
            MergeRequests::UpdateService.new(
              project: example_class.project,
              current_user: user,
              params: { label_ids: [label.id] }
            ).execute(mr)
          end

          mr
        end

        def create_data_for_end_event(mr, example_class)
          mr.metrics.update!(merged_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between MR first assigned at and MR closed time' do
        let(:start_event_identifier) { :merge_request_first_assigned_at }
        let(:end_event_identifier) { :merge_request_closed }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true).tap do |mr|
            create(:merge_request_assignment_event, merge_request: mr)
          end
        end

        def create_data_for_end_event(mr, _example_class)
          mr.metrics.update!(latest_closed_at: Time.current)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end

      context 'between MR created and MR first assigned at time' do
        let(:start_event_identifier) { :merge_request_created }
        let(:end_event_identifier) { :merge_request_first_assigned_at }

        def create_data_for_start_event(example_class)
          create(:merge_request, source_project: example_class.project, allow_broken: true)
        end

        def create_data_for_end_event(mr, _example_class)
          create(:merge_request_assignment_event, merge_request: mr)
        end

        it_behaves_like 'custom Value Stream Analytics Stage'
      end
    end
  end

  context 'when `Analytics::CycleAnalytics::Stage` is given' do
    let(:aggregated_data_collector_enabled) { true }

    it_behaves_like 'test various start and end event combinations' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_value_stream) { create(:cycle_analytics_value_stream, namespace: group) }
      let_it_be(:project) { create(:project, :repository, group: group) }
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:other_label) { create(:group_label, group: group) }

      let(:start_event_label) { nil }
      let(:end_event_label) { nil }

      let!(:stage) do
        Analytics::CycleAnalytics::Stage.create!(
          name: 'My Stage',
          namespace: group,
          start_event_identifier: start_event_identifier,
          end_event_identifier: end_event_identifier,
          start_event_label: start_event_label,
          end_event_label: end_event_label,
          value_stream: group_value_stream
        )
      end

      before do
        aggregate_vsa_data(group)
      end

      before_all do
        group.add_member(user, GroupMember::MAINTAINER)
      end
    end

    context 'when filter parameters are given' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project1) { create(:project, :repository, group: group) }
      let_it_be(:project2) { create(:project, :repository, group: group) }
      let_it_be(:stage) do
        create(:cycle_analytics_stage,
               name: 'My Stage',
               namespace: group,
               start_event_identifier: :merge_request_created,
               end_event_identifier: :merge_request_merged
              )
      end

      let(:merge_request) { project2.merge_requests.first }

      let(:data_collector_params) do
        {
          created_after: Time.zone.local(2019, 1, 1),
          current_user: user
        }
      end

      subject do
        params = Gitlab::Analytics::CycleAnalytics::RequestParams.new(data_collector_params).to_data_collector_params

        described_class.new(stage: stage, params: params).records_fetcher.serialized_records
      end

      before do
        group.add_member(user, GroupMember::MAINTAINER)

        travel_to(Time.zone.local(2019, 6, 1))
        mr = create(:merge_request, source_project: project1)
        mr.metrics.update!(merged_at: 1.hour.from_now)

        mr = create(:merge_request, source_project: project2)
        mr.metrics.update!(merged_at: 1.hour.from_now)
        travel_back
      end

      shared_examples 'filter examples' do
        it 'provides filtered results' do
          expect(subject.size).to eq(1)

          expect(subject.first[:title]).to eq(merge_request.title)
          expect(subject.first[:iid]).to eq(merge_request.iid.to_s)
        end
      end

      context 'when `project_ids` parameter is given' do
        before do
          data_collector_params[:project_ids] = [project2.id]

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when `assignee_username` is given' do
        let(:assignee) { create(:user) }

        before do
          merge_request.assignees << assignee

          data_collector_params[:assignee_username] = [assignee.username]

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when `author_username` is given' do
        let(:author) { create(:user) }

        before do
          merge_request.update!(author: author)

          data_collector_params[:author_username] = author.username

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when `label_name` is given' do
        let(:label) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = [label.name]

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when `Any` `label_name` is given' do
        let(:label) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = ['Any']

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when two labels are given' do
        let(:label1) { create(:group_label, group: group) }
        let(:label2) { create(:group_label, group: group) }

        before do
          MergeRequests::UpdateService.new(
            project: merge_request.project,
            current_user: user,
            params: { label_ids: [label1.id, label2.id] }
          ).execute(merge_request)

          data_collector_params[:label_name] = [label1.name, label2.name]

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end

      context 'when `milestone_title` is given' do
        let(:milestone) { create(:milestone, group: group) }

        before do
          merge_request.update!(milestone: milestone)

          data_collector_params[:milestone_title] = milestone.title

          aggregate_vsa_data(group)
        end

        it_behaves_like 'filter examples'
      end
    end
  end

  describe 'limit count' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }

    let(:merge_request) { merge_requests.first }

    let(:stage) do
      Analytics::CycleAnalytics::Stage.new(
        name: 'My Stage',
        namespace: group,
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged
      )
    end

    before do
      merge_requests = create_list(:merge_request, 3, :unique_branches, target_project: project, source_project: project)
      merge_requests.each { |mr| mr.metrics.update!(merged_at: 10.days.from_now) }

      project.add_member(user, Gitlab::Access::DEVELOPER)
    end

    subject(:count) do
      described_class.new(stage: stage, params: {
        from: 5.months.ago,
        to: 5.months.from_now,
        current_user: user
      }).count
    end

    context 'when limit is reached' do
      before do
        stub_const('Gitlab::Analytics::CycleAnalytics::DataCollector::MAX_COUNT', 2)
      end

      it 'shows the MAX COUNT' do
        is_expected.to eq(2)
      end
    end

    context 'when limit is not reached' do
      it 'shows the actual count' do
        is_expected.to eq(3)
      end
    end
  end
end
