# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/reporting/show' do
  let_it_be(:allowlist) { create_list(:user, 2).map(&:username) }
  let_it_be(:alertlist) { create_list(:user, 2).map(&:id) }

  let(:group) { create(:group) }

  before do
    allow(group).to receive(:unique_project_download_limit_enabled?).and_return(true)

    group.namespace_settings.update!(
      unique_project_download_limit: 1,
      unique_project_download_limit_interval_in_seconds: 2,
      unique_project_download_limit_allowlist: allowlist,
      unique_project_download_limit_alertlist: alertlist,
      auto_ban_user_on_excessive_projects_download: true
    )

    assign(:group, group)
  end

  it 'renders the settings app root with the correct data attributes', :aggregate_failures do
    render

    expect(rendered).to have_selector('#js-unique-project-download-limit-settings-form')

    expect(rendered).to have_selector("[data-group-full-path='#{group.full_path}']")
    expect(rendered).to have_selector('[data-max-number-of-repository-downloads="1"]')
    expect(rendered).to have_selector('[data-max-number-of-repository-downloads-within-time-period="2"]')
    expect(rendered).to have_selector("[data-git-rate-limit-users-allowlist='#{allowlist}']")
    expect(rendered).to have_selector("[data-git-rate-limit-users-alertlist='#{alertlist}']")
    expect(rendered).to have_selector("[data-auto-ban-user-on-excessive-projects-download='true']")
  end

  context 'when group has no settings record' do
    before do
      group.namespace_settings.destroy!
      group.reload
    end

    it 'renders the settings app root with the correct data attributes containing default values',
      :aggregate_failures do
      render

      expect(rendered).to have_selector('#js-unique-project-download-limit-settings-form')

      expect(rendered).to have_selector('[data-max-number-of-repository-downloads="0"]')
      expect(rendered).to have_selector('[data-max-number-of-repository-downloads-within-time-period="0"]')
      expect(rendered).to have_selector("[data-git-rate-limit-users-allowlist='[]']")
      expect(rendered).to have_selector("[data-git-rate-limit-users-alertlist='[]']")
      expect(rendered).to have_selector("[data-auto-ban-user-on-excessive-projects-download='false']")
    end
  end

  context 'when feature is not enabled for the group' do
    before do
      allow(group).to receive(:unique_project_download_limit_enabled?).and_return(false)
    end

    it 'does not render the settings app root' do
      render

      expect(rendered).not_to have_selector('#js-unique-project-download-limit-settings-form')
    end
  end
end
