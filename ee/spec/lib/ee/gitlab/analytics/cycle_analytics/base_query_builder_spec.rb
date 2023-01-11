# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::BaseQueryBuilder do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_in_group) { create(:project, :repository, group: group) }
  let_it_be(:project_in_subgroup) { create(:project, :repository, group: subgroup) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    project_outside_group.add_maintainer(user)
  end

  context 'when the subject is `Issue`' do
    let(:issue_in_project) { create(:issue, project: project_in_group, created_at: 5.days.ago) }
    let(:issue_in_subgroup_project) { create(:issue, project: project_in_subgroup, created_at: 5.days.ago) }
    let(:issue_outside_group) { create(:issue, project: project_outside_group, created_at: 5.days.ago) }

    before do
      [issue_in_project, issue_in_subgroup_project, issue_outside_group].each do |issue|
        issue.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
      end
    end

    it 'loads Issue records within the given Group' do
      stage = build(:cycle_analytics_stage, {
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_first_mentioned_in_commit,
        namespace: group
      })

      result = described_class.new(stage: stage, params: { current_user: user }).build

      expect(result).to contain_exactly(issue_in_project, issue_in_subgroup_project)
    end
  end

  context 'when the subject is `MergeRequest`' do
    let(:mr_in_project) { create(:merge_request, source_project: project_in_group, created_at: 5.days.ago) }
    let(:mr_in_subgroup_project) { create(:merge_request, source_project: project_in_subgroup, created_at: 5.days.ago) }
    let(:mr_outside_group) { create(:merge_request, source_project: project_outside_group, created_at: 5.days.ago) }

    before do
      [mr_in_project, mr_in_subgroup_project, mr_outside_group].each do |mr|
        mr.metrics.update!(merged_at: 2.days.ago)
      end
    end

    it 'loads MergeRequest records within the given Group' do
      stage = build(:cycle_analytics_stage, {
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged,
        namespace: group
      })

      result = described_class.new(stage: stage, params: { current_user: user }).build

      expect(result).to contain_exactly(mr_in_project, mr_in_subgroup_project)
    end
  end
end
