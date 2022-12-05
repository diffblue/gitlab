# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupAnalytics', feature_category: :devops_reports do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:path) { group_path(group) }

  before do
    stub_licensed_features(group_activity_analytics: true)

    group.add_developer(user)
    sign_in(user)
  end

  it 'renders the container' do
    visit path

    expect(page).to have_css('#js-group-activity')
  end
end
