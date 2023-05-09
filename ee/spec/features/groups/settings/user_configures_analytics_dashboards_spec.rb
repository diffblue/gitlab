# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Settings > Analytics Dashboards', :js, feature_category: :value_stream_management do
  include ListboxHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }

  before do
    sign_in(user)
  end

  context 'without correct license' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: false)

      visit edit_group_path(group)
    end

    it 'does not show the Analytics Dashboards config' do
      expect(page).not_to have_content 'Analytics Dashboards'
    end
  end

  context 'with correct license' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: true)

      visit edit_group_path(group)
    end

    it 'allows to select a project in a subgroup for the Analytics Dashboards config' do
      page.within '.analytics-dashboards-settings form' do
        select_from_listbox(project.full_name, from: 'Search for project')

        click_button 'Save changes'

        expect(page).to have_content(project.full_name)
      end
    end
  end
end
