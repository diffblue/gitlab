# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'contribution analytics', feature_category: :value_stream_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_developer(user)
    login_as(user)
  end

  it 'redirects from -/analytics to -/analytics/value_stream_analytics' do
    get "/groups/#{group.full_path}/-/analytics"

    expect(response).to redirect_to(group_analytics_cycle_analytics_path(group.full_path))
  end
end
