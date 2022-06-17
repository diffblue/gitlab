# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Usage quota limitations banner", :saas do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace, owner: user) }
  let_it_be(:personal_project1) { create(:project, namespace: namespace) }
  let_it_be(:personal_project2) { create(:project, namespace: namespace) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_project) { create(:project, namespace: group) }

  let(:banner_title) { _('Your project has limited quotas and features') }
  let(:banner_selector) { '.js-project-usage-limitations-callout' }

  before do
    stub_application_setting(check_namespace_plan: true)
    group.add_owner(user)
    sign_in(user)
  end

  context 'when free user cap is in effect' do
    before do
      stub_feature_flags(free_user_cap: true)
    end

    it 'shows the banner in all personal projects initially' do
      visit(project_usage_quotas_path(personal_project1))

      expect(page.find(banner_selector)).to have_text(banner_title)

      visit(project_usage_quotas_path(personal_project2))

      expect(page.find(banner_selector)).to have_text(banner_title)
    end

    it 'does not show the banner on group projects' do
      visit(project_usage_quotas_path(group_project))

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)
    end

    it 'remembers that the user has dismissed the banner & does not show it again', :js do
      visit(project_usage_quotas_path(personal_project1))

      expect(page.find(banner_selector)).to have_text(banner_title)

      page.within(banner_selector) do
        click_button 'Dismiss'
      end

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)

      visit(project_usage_quotas_path(personal_project2))

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)

      # A bit of cleanup
      user.callouts.find_by(feature_name: 'personal_project_limitations_banner').delete
    end
  end

  context 'when free user cap is not in effect' do
    before do
      stub_feature_flags(free_user_cap: false)
    end

    it 'does not show the banner on personal projects' do
      visit(project_usage_quotas_path(personal_project1))

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)

      visit(project_usage_quotas_path(personal_project2))

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)
    end

    it 'does not show the banner on group projects' do
      visit(project_usage_quotas_path(group_project))

      expect(page).to have_no_selector(banner_selector)
      expect(page).not_to have_text(banner_title)
    end
  end
end
