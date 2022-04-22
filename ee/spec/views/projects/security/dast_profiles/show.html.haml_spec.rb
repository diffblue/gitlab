# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/dast_profiles/show", type: :view do
  before do
    @project = create(:project)
    render
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('.js-dast-profiles')
  end

  it 'passes new dast site profile path' do
    expect(rendered).to include '/security/configuration/profile_library/dast_site_profiles/new'
  end

  it 'passes new dast scanner profile path' do
    expect(rendered).to include '/security/configuration/profile_library/dast_scanner_profiles/new'
  end

  it 'passes project\'s full path' do
    expect(rendered).to include @project.path_with_namespace
  end
end
