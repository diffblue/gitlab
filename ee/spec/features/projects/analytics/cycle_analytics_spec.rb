# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Value stream analytics', :js, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }

  let(:empty_state_selector) { '[data-testid="vsa-empty-state"]' }
  let(:value_stream_selector) { '[data-testid="dropdown-value-streams"]' }
  let(:duration_chart_selector) { '[data-testid="vsa-duration-chart"]' }
  let(:metrics_groups_selector) { '[data-testid="vsa-metrics-group"]' }

  before_all do
    group.add_owner(user)
  end

  shared_examples 'Unlicensed Value Stream Analytics' do
    before do
      visit project_cycle_analytics_path(project)
    end

    it 'does not render the premium features' do
      expect(page).not_to have_selector(value_stream_selector)
      expect(page).not_to have_selector(duration_chart_selector)
    end

    it 'renders vsa metrics' do
      metrics_groups = page.all(metrics_groups_selector)
      expect(metrics_groups.count).to eq(2)

      expect(metrics_groups.first).to have_content "Key metrics"
      expect(metrics_groups.last).to have_content "DORA metrics"
    end
  end

  context 'with the `cycle_analytics_for_projects` license' do
    before do
      stub_licensed_features(cycle_analytics_for_projects: true)

      project.add_maintainer(user)
      sign_in(user)
    end

    it 'renders the customizable VSA empty state' do
      visit project_cycle_analytics_path(project)

      expect(page).to have_selector(empty_state_selector)
      expect(page).to have_text(s_('CycleAnalytics|Custom value streams to measure your DevSecOps lifecycle'))
    end
  end

  context 'with `cycle_analytics_for_projects` disabled' do
    before do
      stub_licensed_features(cycle_analytics_for_projects: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it_behaves_like 'Unlicensed Value Stream Analytics'
  end

  context 'with `vsa_group_and_project_parity` disabled' do
    before do
      stub_licensed_features(cycle_analytics_for_projects: true)
      stub_feature_flags(vsa_group_and_project_parity: false)

      project.add_maintainer(user)
      sign_in(user)
    end

    it_behaves_like 'Unlicensed Value Stream Analytics'
  end
end
