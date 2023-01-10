# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Settings > User configures Insights', :js, feature_category: :value_stream_management do
  include Select2Helper

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be(:user) { create(:user).tap { |u| group.add_owner(u) } }

  before do
    sign_in(user)
  end

  context 'without correct license' do
    before do
      stub_licensed_features(insights: false)

      visit edit_group_path(group)
    end

    it 'does not show the Insight config' do
      expect(page).not_to have_content 'Insights'
    end
  end

  context 'with correct license' do
    before do
      stub_licensed_features(insights: true)

      visit edit_group_path(group)
    end

    it 'allows to select a project in a subgroup for the Insights config' do
      expect(page).to have_content 'Insights'

      page.within '.insights-settings form' do
        select2(project.id, from: '#group_insight_attributes_project_id')

        click_button 'Save changes'

        expect(page).to have_content(project.full_name)
      end
    end
  end
end
