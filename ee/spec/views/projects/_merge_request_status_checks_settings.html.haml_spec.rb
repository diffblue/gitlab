# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_merge_request_status_checks_settings' do
  let(:project) { build(:project) }

  before do
    assign(:project, project)

    allow(view).to receive(:status_checks_app_data).and_return({ data: { status_checks_path: 'status-checks/path' } })

    render
  end

  it 'renders the settings title' do
    expect(rendered).to have_content 'Status checks'
  end

  it 'renders the settings description', :aggregate_failures do
    expect(rendered).to have_content 'Check for a status response in merge requests. Learn more.'
    expect(rendered).to have_link 'Learn more', href: '/help/user/project/merge_requests/status_checks'
  end

  it 'renders the settings app element', :aggregate_failures do
    expect(rendered).to have_selector '#js-status-checks-settings'
    expect(rendered).to have_selector "[data-status-checks-path='status-checks/path']"
  end

  it 'renders the loading spinner' do
    expect(rendered).to have_selector '.gl-spinner'
  end
end
