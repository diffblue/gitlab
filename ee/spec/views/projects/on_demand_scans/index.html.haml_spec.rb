# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/on_demand_scans/index", type: :view do
  before do
    @project = create(:project)
    @current_user = create(:user)
    render
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('#js-on-demand-scans')
  end
end
