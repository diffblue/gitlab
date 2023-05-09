# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Settings > User configures Insights', :js, feature_category: :value_stream_management do
  include ListboxHelpers

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
      expect(page).not_to have_content s_('GroupSettings|Configure analytics features for this group')
    end
  end

  context 'with correct license' do
    before do
      stub_licensed_features(insights: true)

      visit edit_group_path(group)
    end

    it 'allows to select a project in a subgroup for the Insights config' do
      page.within '.insights-settings form' do
        select_from_listbox(project.full_name, from: s_('ProjectSelect|Search for project'))

        click_button _('Save changes')

        expect(page).to have_content(project.full_name)
      end
    end
  end
end
