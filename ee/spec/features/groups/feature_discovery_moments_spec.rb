# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Feature Discovery Moments', :js, :aggregate_failures do
  describe 'Advanced Features Dashboard' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:page_title) { s_('InProductMarketing|Discover Premium & Ultimate') }
    let(:start_trial) { s_('InProductMarketing|Start a free trial') }
    let(:contact_sales) { s_('PQL|Contact sales') }

    before do
      stub_application_setting(check_namespace_plan: true)
      group.add_owner(user)
      sign_in(user)
    end

    def expect_shared_experience
      expect(page).to have_text(page_title)
      expect(page).to have_text(s_('InProductMarketing|Access advanced features, build more efficiently, strengthen security and compliance.'))
      expect(page).to have_link(start_trial)
      expect(page).to have_button(contact_sales)

      click_link(start_trial)

      expect(page).to have_current_path(
        new_trial_path(glm_content: 'cross_stage_fdm', glm_source: 'gitlab.com')
      )

      visit(group_advanced_features_dashboard_path(group_id: group))

      click_button(contact_sales)

      expect(page).to have_text(s_('PQL|Contact our Sales team'))
      expect(page).to have_button(s_('PQL|Cancel'))
      expect(page).to have_button(s_('PQL|Submit information'), disabled: true)
    end

    context 'when the cross_stage_fdm experiment is enabled' do
      before do
        stub_experiments(cross_stage_fdm: :candidate)
        visit group_path(group)
      end

      it 'provides the expected feature discovery experience' do
        page.within '.header-help' do
          click_link 'Help'

          expect(page).to have_text(page_title)

          click_link(page_title)
        end

        expect_shared_experience
      end
    end

    context 'when the cross_stage_fdm experiment is not enabled' do
      before do
        visit group_path(group)
      end

      it 'does not provide a link to the FDM page, but still allows access' do
        page.within '.header-help' do
          click_link 'Help'

          expect(page).not_to have_text(page_title)
        end

        visit(group_advanced_features_dashboard_path(group_id: group))

        expect_shared_experience
      end
    end
  end
end
