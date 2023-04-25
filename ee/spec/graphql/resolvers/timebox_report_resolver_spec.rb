# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TimeboxReportResolver do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:subgroup_project) { create(:project, group: subgroup) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:private_subgroup) { create(:group, :private, parent: private_group) }
  let_it_be(:private_project1) { create(:project, group: private_group) }
  let_it_be(:private_project2) { create(:project, group: private_group) }
  let_it_be(:group_member) { create(:user) }
  let_it_be(:private_group_member) { create(:user) }
  let_it_be(:private_project1_member) { create(:user) }
  let_it_be(:private_project2_member) { create(:user) }
  let_it_be(:issues) { create_list(:issue, 2, project: project) }
  let_it_be(:start_date) { Date.today }
  let_it_be(:due_date) { start_date + 2.weeks }

  let(:event_aggregation_service_class) { TimeboxReportService }
  let(:report_service_class) { TimeboxReportService }

  before_all do
    group.add_guest(group_member)
    private_group.add_guest(private_group_member)
    private_project1.add_guest(private_project1_member)
    private_project2.add_guest(private_project2_member)
  end

  before do
    stub_feature_flags(rollup_timebox_chart: false)
    stub_licensed_features(milestone_charts: true, issue_weights: true, iterations: true)
  end

  RSpec.shared_examples 'timebox time series' do
    subject(:result) { resolve(described_class, obj: timebox, ctx: { current_user: current_user }) }

    context 'when authorized to view "project"' do
      let(:current_user) { group_member }

      it 'returns burnup chart data' do
        expect(result).to eq(
          stats: {
            complete: { count: 0, weight: 0 },
            incomplete: { count: 2, weight: 0 },
            total: { count: 2, weight: 0 }
          },
          burnup_time_series: [
            {
              date: start_date + 4.days,
              scope_count: 1,
              scope_weight: 0,
              completed_count: 0,
              completed_weight: 0
            },
            {
              date: start_date + 9.days,
              scope_count: 2,
              scope_weight: 0,
              completed_count: 0,
              completed_weight: 0
            }
          ])
      end
    end
  end

  RSpec.shared_examples 'fetching excessive number of events causes an error' do
    subject(:result) { resolve(described_class, obj: timebox, ctx: { current_user: group_member }) }

    context 'when the service returns an error' do
      before do
        stub_const("#{event_aggregation_service_class.name}::EVENT_COUNT_LIMIT", 1)
      end

      let(:error_message) { 'Burnup chart could not be generated due to too many events' }
      let(:code) { :too_many_events }

      it 'returns error information' do
        expect(result).to eq(error: { message: error_message, code: code })
      end
    end
  end

  RSpec.shared_examples 'checking authorization for timebox report' do
    context 'when fullPath is provided' do
      using RSpec::Parameterized::TableSyntax

      subject { resolve(described_class, obj: timebox, args: { full_path: full_path }, ctx: { current_user: current_user }) }

      context "when no group or project matches the provided fullPath" do
        let(:full_path) { "abc" }
        let(:current_user) { group_member }

        it 'raises a GraphQL exception' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable, "The resource that you are attempting to access does not exist or you don't have permission to perform this action") do
            subject
          end
        end
      end

      context "when current user is not authorized to read group or view project issues, or resource doesn't exist" do
        let(:full_path) { scope.full_path }

        where(:scope, :current_user) do
          ref(:private_group)    | nil
          ref(:private_group)    | ref(:group_member)
          ref(:private_subgroup) | nil
          ref(:private_subgroup) | ref(:group_member)
          ref(:private_subgroup) | ref(:private_project1_member)
          ref(:private_subgroup) | ref(:private_project2_member)
          ref(:private_project1) | nil
          ref(:private_project1) | ref(:group_member)
          ref(:private_project1) | ref(:private_project2_member)
          ref(:private_project2) | nil
          ref(:private_project2) | ref(:group_member)
          ref(:private_project2) | ref(:private_project1_member)
        end

        with_them do
          it 'raises a GraphQL exception' do
            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable, "The resource that you are attempting to access does not exist or you don't have permission to perform this action") do
              subject
            end
          end
        end
      end

      context 'when current user can read group or view project issues' do
        let(:full_path) { scope.full_path }

        where(:scope, :current_user, :authorized_projects) do
          ref(:group)            | ref(:group_member)            | lazy { [project, subgroup_project] }
          ref(:subgroup)         | ref(:group_member)            | lazy { [subgroup_project] }
          ref(:subgroup_project) | ref(:group_member)            | lazy { [subgroup_project] }
          ref(:private_group)    | ref(:private_group_member)    | lazy { [private_project1, private_project2] }
          # As long as a user can read a group ("private_group"),
          # the user should be able to see the count of the issues coming from the projects to which the user doesn't have access.
          ref(:private_group)    | ref(:private_project1_member) | lazy { [private_project1, private_project2] }
          ref(:private_group)    | ref(:private_project2_member) | lazy { [private_project1, private_project2] }
          ref(:private_project1) | ref(:private_project1_member) | lazy { [private_project1] }
          ref(:private_project2) | ref(:private_project2_member) | lazy { [private_project2] }
          ref(:private_subgroup) | ref(:private_group_member)    | lazy { [] }
        end

        with_them do
          it 'passes projects to the timebox report service' do
            expect(report_service_class).to receive(:new).with(timebox, a_collection_containing_exactly(*authorized_projects)).and_call_original

            subject
          end
        end
      end
    end
  end

  context 'when timebox is a milestone' do
    let_it_be(:timebox) { create(:milestone, project: project, start_date: start_date, due_date: due_date) }

    before_all do
      create(:resource_milestone_event, issue: issues[0], milestone: timebox, action: :add, created_at: start_date + 4.days)
      create(:resource_milestone_event, issue: issues[1], milestone: timebox, action: :add, created_at: start_date + 9.days)
    end

    it_behaves_like 'timebox time series'
    it_behaves_like 'checking authorization for timebox report'
    it_behaves_like 'fetching excessive number of events causes an error'

    it 'uses TimeboxReportService' do
      expect(TimeboxReportService).to receive(:new).and_call_original

      resolve(described_class, obj: timebox, ctx: { current_user: group_member })
    end
  end

  context 'when timebox is an iteration' do
    let_it_be(:timebox) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group), start_date: start_date, due_date: due_date) }

    before_all do
      create(:resource_iteration_event, issue: issues[0], iteration: timebox, action: :add, created_at: start_date + 4.days)
      create(:resource_iteration_event, issue: issues[1], iteration: timebox, action: :add, created_at: start_date + 9.days)
    end

    it_behaves_like 'timebox time series'
    it_behaves_like 'checking authorization for timebox report'
    it_behaves_like 'fetching excessive number of events causes an error'

    it 'uses TimeboxReportService' do
      expect(TimeboxReportService).to receive(:new).and_call_original

      resolve(described_class, obj: timebox, ctx: { current_user: group_member })
    end
  end

  context 'when "rollup_timebox_chart" feature flag is enabled' do
    let(:event_aggregation_service_class) { Timebox::EventAggregationService }
    let(:report_service_class) { Timebox::RollupReportService }

    context 'when FF is enabled for group' do
      let_it_be(:timebox) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group), start_date: start_date, due_date: due_date) }

      before do
        stub_feature_flags(rollup_timebox_chart: group)
      end

      it 'uses Timebox::RollupReportService' do
        expect(Timebox::RollupReportService).to receive(:new).and_call_original

        resolve(described_class, obj: timebox, ctx: { current_user: group_member })
      end

      context 'when timebox is an iteration' do
        before_all do
          create(:resource_iteration_event, issue: issues[0], iteration: timebox, action: :add, created_at: start_date + 4.days)
          create(:resource_iteration_event, issue: issues[1], iteration: timebox, action: :add, created_at: start_date + 9.days)
        end

        it_behaves_like 'checking authorization for timebox report'
        it_behaves_like 'fetching excessive number of events causes an error'

        context 'when authorized to view "project"' do
          subject(:result) { resolve(described_class, obj: timebox, ctx: { current_user: current_user }) }

          let(:current_user) { group_member }

          it 'returns burnup chart data' do
            expect(result).to eq(
              stats: {
                complete: { count: 0, weight: 0 },
                incomplete: { count: 2, weight: 0 },
                total: { count: 2, weight: 0 }
              },
              burnup_time_series: [
                {
                  date: start_date + 4.days,
                  scope_count: 1,
                  scope_weight: 0,
                  completed_count: 0,
                  completed_weight: 0
                },
                {
                  date: start_date + 9.days,
                  scope_count: 2,
                  scope_weight: 0,
                  completed_count: 0,
                  completed_weight: 0
                }
              ])
          end
        end
      end
    end

    context 'when FF is enabled for project' do
      let_it_be(:timebox) { create(:milestone, project: project, start_date: start_date, due_date: due_date) }

      before do
        stub_feature_flags(rollup_timebox_chart: project)
      end

      it 'uses Timebox::RollupReportService' do
        expect(Timebox::RollupReportService).to receive(:new).and_call_original

        resolve(described_class, obj: timebox, ctx: { current_user: group_member })
      end

      context 'when timebox is a milestone' do
        before_all do
          create(:resource_milestone_event, issue: issues[0], milestone: timebox, action: :add, created_at: start_date + 4.days)
          create(:resource_milestone_event, issue: issues[1], milestone: timebox, action: :add, created_at: start_date + 9.days)
        end

        it_behaves_like 'checking authorization for timebox report'
        it_behaves_like 'fetching excessive number of events causes an error'

        context 'when authorized to view "project"' do
          subject(:result) { resolve(described_class, obj: timebox, ctx: { current_user: current_user }) }

          let(:current_user) { group_member }

          it 'returns burnup chart data' do
            expect(result).to eq(
              stats: {
                complete: { count: 0, weight: 0 },
                incomplete: { count: 2, weight: 0 },
                total: { count: 2, weight: 0 }
              },
              burnup_time_series: [
                {
                  date: start_date + 4.days,
                  scope_count: 1,
                  scope_weight: 0,
                  completed_count: 0,
                  completed_weight: 0
                },
                {
                  date: start_date + 9.days,
                  scope_count: 2,
                  scope_weight: 0,
                  completed_count: 0,
                  completed_weight: 0
                }
              ])
          end
        end
      end
    end
  end
end
