# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Code suggestions third party alert', :saas, :js, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :public, namespace: group) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    user.update_attribute(:code_suggestions, true)
    group.update_attribute(:code_suggestions, true)
    group.update_attribute(:third_party_ai_features_enabled, true)
    sign_in(user)
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

    visit root_path
    expect_banner_to_be_absent
  end

  it 'does not display the banner when the feature flag is off' do
    stub_feature_flags(code_suggestions_third_party_alert: false)
    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  it 'can be dismissed' do
    visit group_path(group)
    dismiss_button.click

    expect_group_page_for(group)
    expect_banner_to_be_absent

    visit group_path(group)

    expect_group_page_for(group)
    expect_banner_to_be_absent
  end

  def dismiss_button
    find('button[data-testid="code_suggestions_third_party_alert_dismiss"]')
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
    expect(page).to have_text title
  end

  def expect_banner_to_be_absent
    expect(page).not_to have_text title
  end

  def title
    'We use third-party AI services to improve Code Suggestions'
  end
end
