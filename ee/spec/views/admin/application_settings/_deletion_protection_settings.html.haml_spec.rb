# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_deletion_protection_settings' do
  let_it_be(:application_setting) do
    build(
      :application_setting,
      deletion_adjourned_period: 1,
      delayed_group_deletion: false,
      delayed_project_deletion: false
    )
  end

  before do
    stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
    assign(:application_setting, application_setting)
  end

  it 'renders the deletion protection settings app root' do
    render

    expect(rendered).to have_selector('#js-admin-deletion-protection-settings')
    expect(rendered).to have_selector('[data-deletion-adjourned-period="1"]')
    expect(rendered).to have_selector('[data-delayed-group-deletion="false"]')
    expect(rendered).to have_selector('[data-delayed-project-deletion="false"]')
  end
end
