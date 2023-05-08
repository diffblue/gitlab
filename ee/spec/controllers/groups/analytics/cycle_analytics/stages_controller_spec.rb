# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::StagesController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let_it_be(:stages) do
    [
      create(:cycle_analytics_stage, namespace: group, name: "Issue", relative_position: 1),
      create(:cycle_analytics_stage, namespace: group, name: "Code", relative_position: 2)
    ]
  end

  let_it_be(:value_stream) do
    create(
      :cycle_analytics_value_stream,
      namespace: group,
      name: 'First value stream',
      stages: stages
    )
  end

  let(:params) { { group_id: group, value_stream_id: value_stream.id } }
  let(:namespace) { group }

  it_behaves_like 'Value Stream Analytics Stages controller'
end
