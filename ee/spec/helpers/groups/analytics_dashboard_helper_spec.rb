# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AnalyticsDashboardHelper, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:current_user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  before do
    stub_licensed_features(group_level_analytics_dashboard: true)
    group.namespace_settings.update_attribute(:experiment_features_enabled, true)
  end

  describe '#group_analytics_dashboard_available?' do
    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?).with(current_user, :read_group_analytics_dashboards, group).and_return(true)
    end

    it 'is true for the group' do
      expect(helper.group_analytics_dashboard_available?(group)).to be(true)
    end

    context 'when experimental features are disabled' do
      before do
        group.root_ancestor.namespace_settings.update_attribute(:experiment_features_enabled, false)
      end

      it 'is false for the group' do
        expect(helper.group_analytics_dashboard_available?(group)).to be(false)
      end
    end

    context 'when the current user does not have permission' do
      before do
        allow(helper).to receive(:current_user) { current_user }
        allow(helper).to receive(:can?).with(current_user, :read_group_analytics_dashboards, group).and_return(false)
      end

      it 'is false for the group' do
        expect(helper.group_analytics_dashboard_available?(group)).to be(false)
      end
    end
  end
end
