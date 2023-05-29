# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Code suggestions alert', :saas, :js, feature_category: :code_suggestions do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
  end

  it 'displays the banner at the required pages' do
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_present

    visit group_path(subgroup)

    expect_group_page_for(subgroup)
    expect_banner_to_be_present

    visit project_path(project)

    expect_project_page_for(project)
    expect_banner_to_be_present
  end

  it 'does not display the banner when the feature flag is off' do
    stub_feature_flags(code_suggestions_alert: false)
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  it 'can be dismissed' do
    visit group_path(group)
    dismiss_button.click

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  it 'remains dismissed' do
    visit group_path(group)
    dismiss_button.click

    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  context 'when new navigation alert is present' do
    let_it_be(:user) { create(:user, use_new_navigation: true) }

    before do
      sign_in(user)
      visit group_path(group)
    end

    it 'does not show code suggestions alert' do
      expect_new_nav_alert_to_be_present
      expect_group_page_for(group)
      expect_banner_to_be_absent
    end

    context 'when user dismisses new navigation alert' do
      it 'hides new nav alert and shows code suggestions alert' do
        expect_new_nav_alert_to_be_present

        page.within(find('[data-feature-id="new_navigation_callout"]')) do
          find('[data-testid="close-icon"]').click
        end

        wait_for_requests

        # simulate delay in showing code suggestions alert
        travel_to(Time.current + 31.minutes) do
          visit group_path(group)

          expect_new_nav_alert_be_absent
          expect_banner_to_be_present
        end
      end
    end
  end

  def dismiss_button
    find('button[data-testid="code_suggestions_alert_dismiss"]')
  end

  def expect_group_page_for(group)
    expect(page).to have_text group.name
    expect(page).to have_text "Group ID: #{group.id}"
  end

  def expect_project_page_for(project)
    expect(page).to have_text project.namespace.name
    expect(page).to have_text project.name
  end

  def expect_banner_to_be_present
    expect(page).to have_text 'Get started with Code Suggestions'
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text 'Get started with Code Suggestions'
  end

  def expect_new_nav_alert_to_be_present
    expect(page).to have_content _('Welcome to a new navigation experience')
  end

  def expect_new_nav_alert_be_absent
    expect(page).not_to have_content _('Welcome to a new navigation experience')
  end
end
