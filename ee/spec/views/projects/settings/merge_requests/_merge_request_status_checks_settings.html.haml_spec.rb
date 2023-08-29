# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/merge_requests/_merge_request_status_checks_settings' do
  let(:project) { build(:project) }

  before do
    assign(:project, project)

    allow(view).to receive(:status_checks_app_data).and_return({ data: { status_checks_path: 'status-checks/path' } })

    render
  end

  it 'renders the settings app element', :aggregate_failures do
    expect(rendered).to have_selector '#js-status-checks-settings'
    expect(rendered).to have_selector "[data-status-checks-path='status-checks/path']"
  end

  it 'renders the loading spinner' do
    expect(rendered).to have_selector '.gl-spinner'
  end
end
