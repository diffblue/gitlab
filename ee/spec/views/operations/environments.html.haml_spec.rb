# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'operations/environments.html.haml' do
  it 'renders the frontend configuration' do
    render

    expect(rendered).to match %r{data-add-path="/-/operations/environments.json"}
    expect(rendered).to match %r{data-list-path="/-/operations/environments.json"}
    expect(rendered).to match %r{data-empty-dashboard-svg-path="/assets/illustrations/empty-state/empty-radar-md.*\.svg"}
    expect(rendered).to match %r{data-empty-dashboard-help-path="/help/ci/environments/environments_dashboard.md"}
    expect(rendered).to match %r{data-environments-dashboard-help-path="/help/ci/environments/environments_dashboard.md"}
  end
end
