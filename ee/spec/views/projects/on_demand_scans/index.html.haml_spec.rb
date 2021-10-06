# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/on_demand_scans/index", type: :view do
  before do
    @project = create(:project)
    render
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('#js-on-demand-scans-form')
  end

  it 'passes on-demand scans docs page URL' do
    expect(rendered).to include '/help/user/application_security/dast/index#on-demand-scans'
  end
end
