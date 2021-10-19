# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Aggregated::BaseQueryBuilder do
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: sub_group) }
  let_it_be(:project_2) { create(:project, group: sub_group) }

  let_it_be(:other_group) { create(:group) }
  let_it_be(:other_project) { create(:project, group: other_group) }

  let_it_be(:stage) do
    create(:cycle_analytics_group_stage,
           group: group,
           start_event_identifier: :issue_created,
           end_event_identifier: :issue_deployed_to_production
          )
  end

  let_it_be(:stage_event_1) do
    create(:cycle_analytics_issue_stage_event,
           stage_event_hash_id: stage.stage_event_hash_id,
           group_id: sub_group.id,
           project_id: project_1.id,
           issue_id: 1
          )
  end

  let_it_be(:stage_event_2) do
    create(:cycle_analytics_issue_stage_event,
           stage_event_hash_id: stage.stage_event_hash_id,
           group_id: sub_group.id,
           project_id: project_2.id,
           issue_id: 2
          )
  end

  let_it_be(:stage_event_3) do
    create(:cycle_analytics_issue_stage_event,
           stage_event_hash_id: stage.stage_event_hash_id,
           group_id: other_group.id,
           project_id: other_project.id,
           issue_id: 3
          )
  end

  let(:params) do
    {
      from: 1.year.ago.to_date,
      to: Date.today
    }
  end

  subject(:issue_ids) { described_class.new(stage: stage, params: params).build.pluck(:issue_id) }

  it 'looks up items within the group hierarchy' do
    expect(issue_ids).to eq([stage_event_1.issue_id, stage_event_2.issue_id])
    expect(issue_ids).not_to include([stage_event_3.issue_id])
  end

  it 'accepts project_ids filter' do
    params[:project_ids] = [project_1.id, other_project.id]

    expect(issue_ids).to eq([stage_event_1.issue_id])
  end
end
