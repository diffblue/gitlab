# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group reporting settings' do
  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:feature_flag_enabled) { true }
  let(:licensed_feature_available) { true }
  let(:current_limit) { 1 }
  let(:current_interval) { 9 }

  before do
    stub_feature_flags(limit_unique_project_downloads_per_namespace_user: feature_flag_enabled)
    stub_licensed_features(unique_project_download_limit: licensed_feature_available)

    sign_in(user)

    group.add_owner(user)

    group.namespace_settings.update!(
      unique_project_download_limit: current_limit,
      unique_project_download_limit_interval: current_interval
    )

    visit group_settings_reporting_path(group)
  end

  it 'displays the side bar menu item' do
    page.within('.shortcuts-settings') do
      expect(page).to have_link 'Reporting', href: group_settings_reporting_path(group)
    end
  end

  it 'updates the settings' do
    limit_label = s_('GroupSettings|Unique project download limit')
    interval_label = s_('GroupSettings|Unique project download limit interval in seconds')

    expect(page).to have_field(limit_label, with: current_limit)
    expect(page).to have_field(interval_label, with: current_interval)

    new_limit = 5
    new_interval = 300

    fill_in(limit_label, with: new_limit)
    fill_in(interval_label, with: new_interval)

    click_button 'Save changes'

    group.reload

    expect(group.namespace_settings.unique_project_download_limit).to eq new_limit
    expect(group.namespace_settings.unique_project_download_limit_interval).to eq new_interval

    expect(page).to have_field(limit_label, with: new_limit)
    expect(page).to have_field(interval_label, with: new_interval)
  end

  it 'displays validation errors' do
    fill_in s_('GroupSettings|Unique project download limit'), with: -1
    fill_in s_('GroupSettings|Unique project download limit interval in seconds'), with: -1

    click_button 'Save changes'

    expect(page).to have_content('Unique project download limit must be greater than or equal to 0')
    expect(page).to have_content('Unique project download limit interval must be greater than or equal to 0')
  end
end
