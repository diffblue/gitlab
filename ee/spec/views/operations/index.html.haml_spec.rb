# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'operations/index.html.haml' do
  it 'renders the frontend configuration' do
    render

    expect(rendered).to match %r{data-add-path="/-/operations.json"}
    expect(rendered).to match %r{data-list-path="/-/operations.json"}
    expect(rendered).to match %{data-empty-dashboard-svg-path="/assets/illustrations/operations-dashboard_empty.*\.svg"}
    expect(rendered).to match %r{data-empty-dashboard-help-path="/help/user/operations_dashboard/index.md"}
  end
end
