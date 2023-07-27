# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'product_analytics/_project_settings', feature_category: :product_analytics_data_management do
  let_it_be(:project) { build(:project, :with_product_analytics_dashboard) }

  before do
    assign(:project, project)

    allow(controller).to receive(:current_user).and_return(project.owner)
    allow(project.owner).to receive(:can?).and_return(true)
    allow(view).to receive_messages(
      current_user: project.owner,
      expanded: false,
      current_application_settings: Gitlab::CurrentSettings.current_application_settings)

    stub_licensed_features(product_analytics: true)

    view.assign(view_assigns)
  end

  [true, false].each do |product_analytics_enabled|
    it "renders the form correctly for product_analytics_enabled: #{product_analytics_enabled}" do
      stub_feature_flags(product_analytics_dashboards: product_analytics_enabled)

      expect(view.render(partial: 'product_analytics/project_settings'))
        .to product_analytics_enabled ? have_content('Product Analytics') : be_nil
    end
  end
end
