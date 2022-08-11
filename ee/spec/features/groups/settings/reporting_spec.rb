# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group reporting settings', :js do
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
      unique_project_download_limit_interval_in_seconds: current_interval
    )

    visit group_settings_reporting_path(group)
  end

  it 'displays the side bar menu item' do
    page.within('.shortcuts-settings') do
      expect(page).to have_link 'Reporting', href: group_settings_reporting_path(group)
    end
  end

  it 'updates the settings' do
    limit_label = s_('GitAbuse|Number of repositories')
    interval_label = s_('GitAbuse|Reporting time period (seconds)')
    allowlist_label = s_('GitAbuse|Excluded users')

    expect(page).to have_field(limit_label, with: current_limit)
    expect(page).to have_field(interval_label, with: current_interval)
    expect(page).to have_field(allowlist_label)

    new_limit = 5
    new_interval = 300

    fill_in(limit_label, with: new_limit)
    fill_in(interval_label, with: new_interval)
    fill_in(allowlist_label, with: user.name)

    wait_for_requests

    click_button user.name

    click_button _('Save changes')

    wait_for_requests

    expect(page).to have_field(limit_label, with: new_limit)
    expect(page).to have_field(interval_label, with: new_interval)
    expect(page).to have_content(user.name)

    group.reload

    settings = group.namespace_settings
    expect(settings.unique_project_download_limit).to eq new_limit
    expect(settings.unique_project_download_limit_interval_in_seconds).to eq new_interval
    expect(settings.unique_project_download_limit_allowlist).to contain_exactly(user.username)
  end

  it 'displays validation errors' do
    limit_label = s_('GitAbuse|Number of repositories')
    interval_label = s_('GitAbuse|Reporting time period (seconds)')

    fill_in(limit_label, with: '')
    fill_in(interval_label, with: '')
    find('#reporting-time-period').native.send_keys :tab

    expect(page).to have_content(s_("GitAbuse|Number of repositories can't be blank. Set to 0 for no limit."))
    expect(page).to have_content(s_("GitAbuse|Reporting time period can't be blank. Set to 0 for no limit."))
    expect(page).to have_button _('Save changes'), disabled: true

    fill_in(limit_label, with: 10_001)
    fill_in(interval_label, with: 864_001)
    find('#reporting-time-period').native.send_keys :tab

    expect(page).to have_content(
      format(
        s_('GitAbuse|Number of repositories should be between %{minNumRepos}-%{maxNumRepos}.'),
        minNumRepos: 0, maxNumRepos: 10000
      )
    )

    expect(page).to have_content(
      format(
        s_('GitAbuse|Reporting time period should be between %{minTimePeriod}-%{maxTimePeriod} seconds.'),
        minTimePeriod: 0, maxTimePeriod: 864000
      )
    )
    expect(page).to have_button _('Save changes'), disabled: true
  end
end
