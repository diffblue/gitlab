# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AnalyticsDashboardHelper, feature_category: :value_stream_management do
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:group_project) { build_stubbed(:project, group: group) }
  let_it_be(:personal_project) { build_stubbed(:project) }

  before do
    stub_licensed_features(project_level_analytics_dashboard: true)
  end

  describe '#analytics_dashboard_available?' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(product_analytics_dashboards: false)
      end

      it 'is false for group and personal projects' do
        expect(helper.analytics_dashboard_available?(group_project)).to be_falsey
        expect(helper.analytics_dashboard_available?(personal_project)).to be_falsey
      end
    end

    context 'when licensed feature is not available' do
      before do
        stub_licensed_features(project_level_analytics_dashboard: false)
      end

      it 'is false for group and personal projects' do
        expect(helper.analytics_dashboard_available?(group_project)).to be_falsey
        expect(helper.analytics_dashboard_available?(personal_project)).to be_falsey
      end
    end

    it 'is true for group project' do
      expect(helper.analytics_dashboard_available?(group_project)).to be_truthy
    end

    it 'is false for personal project' do
      expect(helper.analytics_dashboard_available?(personal_project)).to be_falsey
    end
  end
end
