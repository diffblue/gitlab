# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include JavaScriptFixturesHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:value_stream) { create(:cycle_analytics_group_value_stream, group: group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_1) { create(:issue, project: project, created_at: 5.days.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 3.days.ago) }

  let(:label) { create(:group_label, name: 'in-code-review', group: group) }

  let(:mr_1) { create(:merge_request, source_project: project, allow_broken: true, created_at: 20.days.ago) }
  let(:mr_2) { create(:merge_request, source_project: project, allow_broken: true, created_at: 19.days.ago) }

  let(:pipeline_1) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr_1.source_branch, sha: mr_1.source_branch_sha, head_pipeline_of: mr_1) }
  let(:pipeline_2) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr_2.source_branch, sha: mr_2.source_branch_sha, head_pipeline_of: mr_2) }

  let(:build_1) { create(:ci_build, :success, pipeline: pipeline_1, author: user) }
  let(:build_2) { create(:ci_build, :success, pipeline: pipeline_2, author: user) }

  let(:label_based_stage) do
    create(:cycle_analytics_group_stage, {
      name: 'label-based-stage',
      parent: group,
      value_stream: value_stream,
      start_event_identifier: :issue_label_added,
      start_event_label_id: label.id,
      end_event_identifier: :issue_label_removed,
      end_event_label_id: label.id
    })
  end

  def prepare_cycle_analytics_data
    group.add_maintainer(user)
    project.add_maintainer(user)

    create_commit_referencing_issue(issue_1)
    create_commit_referencing_issue(issue_2)

    create_merge_request_closing_issue(user, project, issue_1)
    create_merge_request_closing_issue(user, project, issue_2)
    merge_merge_requests_closing_issue(user, project, issue_3)
  end

  def create_deployment
    deploy_master(user, project, environment: 'staging')
    deploy_master(user, project)
  end

  def update_metrics
    issue_1.metrics.update!(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
    issue_2.metrics.update!(first_added_to_board_at: 2.days.ago, first_mentioned_in_commit_at: 1.day.ago)

    mr_1.metrics.update!({
      merged_at: 5.days.ago,
      first_deployed_to_production_at: 1.day.ago,
      latest_build_started_at: 5.days.ago,
      latest_build_finished_at: 1.day.ago,
      pipeline: build_1.pipeline
    })

    mr_2.metrics.update!({
      merged_at: 10.days.ago,
      first_deployed_to_production_at: 5.days.ago,
      latest_build_started_at: 9.days.ago,
      latest_build_finished_at: 7.days.ago,
      pipeline: build_2.pipeline
    })
  end

  def additional_cycle_analytics_metrics
    create(:cycle_analytics_group_stage, parent: group, value_stream: value_stream)

    update_metrics

    deploy_master(user, project, environment: 'staging')
  end

  def create_label_based_cycle_analytics_stage
    label_based_stage

    issue = create(:issue, project: project, created_at: 20.days.ago, author: user)

    travel_to(5.days.ago) do
      Issues::UpdateService.new(
        project: project,
        current_user: user,
        params: { label_ids: [label.id] }
      ).execute(issue)
    end

    travel_to(2.days.ago) do
      Issues::UpdateService.new(
        project: project,
        current_user: user,
        params: { label_ids: [] }
      ).execute(issue)
    end
  end

  before(:all) do
    clean_frontend_fixtures('analytics/value_stream_analytics/')
  end

  describe Groups::Analytics::CycleAnalytics::StagesController, type: :controller do
    render_views

    let(:params) { { created_after: 3.months.ago, created_before: Time.now, group_id: group.full_path } }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      # Persist the default stages
      Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
        group.cycle_analytics_stages.build(params.merge(value_stream: value_stream)).save!
      end

      create_label_based_cycle_analytics_stage

      prepare_cycle_analytics_data
      create_deployment

      additional_cycle_analytics_metrics

      sign_in(user)
    end

    it 'analytics/value_stream_analytics/stages.json' do
      get(:index, params: { group_id: group.name, value_stream_id: value_stream.id }, format: :json)

      expect(response).to be_successful
    end

    Gitlab::Analytics::CycleAnalytics::DefaultStages.all.each do |stage|
      it "analytics/value_stream_analytics/stages/#{stage[:name]}/records.json" do
        stage_id = group.cycle_analytics_stages.find_by(name: stage[:name]).id
        get(:records, params: params.merge({ id: stage_id }), format: :json)

        expect(response).to be_successful
      end

      it "analytics/value_stream_analytics/stages/#{stage[:name]}/median.json" do
        stage_id = group.cycle_analytics_stages.find_by(name: stage[:name]).id
        get(:median, params: params.merge({ id: stage_id }), format: :json)

        expect(response).to be_successful
      end

      it "analytics/value_stream_analytics/stages/#{stage[:name]}/count.json" do
        stage_id = group.cycle_analytics_stages.find_by(name: stage[:name]).id
        get(:count, params: params.merge({ id: stage_id }), format: :json)

        expect(response).to be_successful
      end
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/records.json" do
      get(:records, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/median.json" do
      get(:median, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end

    it "analytics/value_stream_analytics/stages/label-based-stage/count.json" do
      get(:count, params: params.merge({ id: label_based_stage.id }), format: :json)

      expect(response).to be_successful
    end
  end
end
