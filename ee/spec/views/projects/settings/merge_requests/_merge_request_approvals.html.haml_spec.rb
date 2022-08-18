# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/merge_requests/_merge_request_approvals_settings' do
  let(:project) { build(:project) }

  before do
    assign(:project, project)

    allow(view).to receive(:expanded).and_return(true)
    allow(project).to receive(:feature_available?).and_return(true)

    render partial: 'projects/settings/merge_requests/merge_request_approvals_settings'
  end

  it 'renders the settings title' do
    expect(rendered).to have_content 'Merge request approvals'
  end

  it 'renders the settings app element', :aggregate_failures do
    expect(rendered).to have_selector '#js-mr-approvals-settings'
  end

  it 'renders the loading spinner' do
    expect(rendered).to have_selector '.gl-spinner'
  end
end
