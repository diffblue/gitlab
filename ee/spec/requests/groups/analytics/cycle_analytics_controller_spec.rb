# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalyticsController, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let(:value_stream) { create(:cycle_analytics_value_stream, namespace: group) }
  let_it_be(:user) { create(:user) }

  before_all do
    sign_in(user)
    group.add_maintainer(user)
  end

  it 'exposes the query params in data attributes' do
    stub_licensed_features(cycle_analytics_for_groups: true)

    extra_query_params = { weight: '3', epic_id: '1', iteration_id: '2', my_reaction_emoji: 'thumbsup' }

    expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams) do |instance|
      expect(instance).to have_attributes(**extra_query_params)
    end

    get group_analytics_cycle_analytics_path(group, value_stream_id: value_stream, **extra_query_params)

    expect(body).to include('data-weight="3"')
    expect(body).to include('data-epic-id="1"')
    expect(body).to include('data-iteration-id="2"')
    expect(body).to include('data-my-reaction-emoji="thumbsup"')
  end
end
