# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/dast_scanner_profiles/edit", type: :view do
  let_it_be(:scanner_profile) { create(:dast_scanner_profile) }
  let_it_be(:scanner_profile_gid) { ::URI::GID.parse("gid://gitlab/DastScannerProfile/#{scanner_profile.id}") }

  before do
    assign(:project, scanner_profile.project)
    assign(:scanner_profile, scanner_profile)
    assign(:scanner_profile_gid, scanner_profile_gid)
    render
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('.js-dast-scanner-profile-form')
  end

  it 'passes project\'s full path' do
    expect(rendered).to include scanner_profile.project.path_with_namespace
  end

  it 'passes DAST profiles library URL' do
    expect(rendered).to include '/security/configuration/profile_library'
  end

  it 'passes DAST scanner profile\'s data' do
    expect(rendered).to include scanner_profile_gid.to_s
    expect(rendered).to include scanner_profile.name
    expect(rendered).to include scanner_profile.spider_timeout.to_s
    expect(rendered).to include scanner_profile.target_timeout.to_s
  end
end
