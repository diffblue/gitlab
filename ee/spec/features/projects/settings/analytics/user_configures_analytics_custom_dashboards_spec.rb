# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Analytics -> Custom dashboard projects', :js, feature_category: :value_stream_management do
  include ListboxHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be(:upper_project) { create(:project, namespace: group) }

  before do
    sign_in(user)
  end

  context 'without correct license' do
    before do
      stub_licensed_features(project_level_analytics_dashboard: false)

      visit project_settings_analytics_path(project)
    end

    it 'does not show the custom dashboard projects config' do
      expect(page).not_to have_content s_('Custom dashboard projects')
    end
  end

  context 'with correct license' do
    before do
      stub_licensed_features(project_level_analytics_dashboard: true, product_analytics: true)
      stub_feature_flags(product_analytics_admin_settings: true, product_analytics_dashboards: true)

      visit project_settings_analytics_path(project)
    end

    it 'allows to select a project for the Analytics Dashboards config' do
      page.within '[data-testid="analytics-dashboards-settings"]' do
        select_from_listbox(upper_project.full_name, from: s_('ProjectSelect|Search for project'))

        click_button _('Save changes')

        expect(page).to have_content(upper_project.full_name)
      end
    end
  end
end
