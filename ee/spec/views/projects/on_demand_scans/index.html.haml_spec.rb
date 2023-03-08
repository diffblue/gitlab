# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/on_demand_scans/index", :dynamic_analysis,
  feature_category: :dynamic_application_security_testing,
  type: :view do
  before do
    @project = create(:project)
    @current_user = create(:user)
  end

  it 'renders Vue app root' do
    render

    expect(rendered).to have_selector('#js-on-demand-scans')
  end

  context 'when pre scan verification is enabled' do
    it 'render pre scan verification alert' do
      render

      expect(rendered).to render_template(partial: 'projects/on_demand_scans/_pre_scan_verification_alert')
    end
  end

  context 'when pre scan verification is disabled' do
    before do
      stub_feature_flags(dast_pre_scan_verification: false)
    end

    it 'render pre scan verification alert' do
      render

      expect(rendered).not_to render_template(partial: 'projects/on_demand_scans/_pre_scan_verification_alert')
    end
  end
end
