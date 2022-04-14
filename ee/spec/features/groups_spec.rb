# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group' do
  describe 'group edit', :js do
    let_it_be(:user) { create(:user) }

    let_it_be(:group) do
      create(:group, :public).tap do |g|
        g.add_owner(user)
      end
    end

    let(:path) { edit_group_path(group, anchor: 'js-permissions-settings') }
    let(:group_wiki_toggle) { true }

    before do
      stub_feature_flags(group_wiki_settings_toggle: group_wiki_toggle)

      sign_in(user)

      visit path
    end

    context 'wiki_access_level setting' do
      it 'saves new settings', :aggregate_failures do
        expect(page).to have_content('Disable the group-level wiki')

        [Featurable::PRIVATE, Featurable::DISABLED, Featurable::ENABLED].each do |wiki_access_level|
          find(
            ".js-general-permissions-form "\
              "#group_group_feature_attributes_wiki_access_level_#{wiki_access_level}").click

          click_button 'Save changes'

          expect(page).to have_content 'successfully updated'
          expect(group.reload.group_feature.wiki_access_level).to eq wiki_access_level
        end
      end

      context 'when feature flag :group_wiki_settings_toggle is disabled' do
        let(:group_wiki_toggle) { false }

        it 'wiki settings form is not present' do
          expect(page).not_to have_content('Disable the group-level wiki')
        end
      end
    end
  end
end
