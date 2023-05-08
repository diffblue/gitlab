# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::ValueStreamsController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { group }

  let(:path_prefix) { %i[group] }
  let(:params) { { group_id: group.to_param } }
  let(:license_name) { :cycle_analytics_for_groups }

  it_behaves_like 'value stream controller actions'
end
