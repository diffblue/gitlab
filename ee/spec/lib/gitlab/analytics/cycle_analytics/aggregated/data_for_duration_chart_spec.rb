# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Aggregated::DataForDurationChart do
  let_it_be(:stage) { create(:cycle_analytics_stage, start_event_identifier: :issue_created, end_event_identifier: :issue_closed) }
  let_it_be(:project) { create(:project, group: stage.namespace) }
  let_it_be(:issue_1) { create(:issue, project: project) }
  let_it_be(:issue_2) { create(:issue, project: project) }
  let_it_be(:issue_3) { create(:issue, project: project) }

  subject(:result) do
    described_class
      .new(stage: stage, params: {}, query: Analytics::CycleAnalytics::IssueStageEvent.all)
      .average_by_day
  end

  it 'calculates the daily average stage duration' do
    end_timestamp_1 = Time.zone.local(2020, 5, 6, 12, 0)
    end_timestamp_2 = Time.zone.local(2020, 5, 15, 10, 0)

    create(:cycle_analytics_issue_stage_event, issue_id: issue_1.id, start_event_timestamp: end_timestamp_1 - 3.days, end_event_timestamp: end_timestamp_1) # 3 days
    create(:cycle_analytics_issue_stage_event, issue_id: issue_2.id, start_event_timestamp: end_timestamp_2 - 3.days, end_event_timestamp: end_timestamp_2) # 3 days
    create(:cycle_analytics_issue_stage_event, issue_id: issue_3.id, start_event_timestamp: end_timestamp_2 - 1.day, end_event_timestamp: end_timestamp_2) # 1 day

    average_two_days_ago = result[0]
    average_today = result[1]

    expect(average_two_days_ago).to have_attributes(date: end_timestamp_1.to_date, average_duration_in_seconds: 3.days)
    expect(average_today).to have_attributes(date: end_timestamp_2.to_date, average_duration_in_seconds: 2.days)
  end
end
