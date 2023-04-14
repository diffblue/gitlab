# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Value stream analytics', :js, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }
  let_it_be(:project_namespace) { project.project_namespace }

  let(:empty_state_selector) { '[data-testid="vsa-empty-state"]' }
  let(:value_stream_selector) { '[data-testid="dropdown-value-streams"]' }
  let(:duration_chart_selector) { '[data-testid="vsa-duration-overview-chart"]' }
  let(:metrics_groups_selector) { '[data-testid="vsa-metrics-group"]' }
  let(:metrics_selector) { '[data-testid="vsa-metrics"]' }

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

  context 'with custom value streams feature available' do
    let_it_be(:group) { create(:group, name: 'Project with custom value streams available') }
    let_it_be(:project) do
      create(:project, :repository, namespace: group, group: group, name: 'Important project')
    end

    let_it_be(:project_namespace) { project.project_namespace }

    before do
      stub_licensed_features(
        cycle_analytics_for_projects: true,
        cycle_analytics_for_groups: true,
        group_level_analytics_dashboard: true
      )

      project.add_maintainer(user)
      sign_in(user)
    end

    context 'with no value stream' do
      it 'renders the customizable VSA empty state' do
        visit project_cycle_analytics_path(project)

        expect(page).to have_selector(empty_state_selector)
        expect(page).to have_text(s_('CycleAnalytics|Custom value streams to measure your DevSecOps lifecycle'))
      end
    end

    context 'with a value stream created', :sidekiq_inline do
      let_it_be(:value_stream_name) { 'My awesome splendiferous value stream' }
      let_it_be(:stages) do
        [
          create(:cycle_analytics_stage, namespace: project_namespace, name: "Issue", relative_position: 1),
          create(:cycle_analytics_stage, namespace: project_namespace, name: "Code", relative_position: 2)
        ]
      end

      let_it_be(:value_stream) do
        create(:cycle_analytics_value_stream,
          namespace: project_namespace,
          name: value_stream_name,
          stages: stages)
      end

      before do
        # otherwise we get the "Data is collecting and loading"
        create_value_stream_aggregation(project_namespace)

        visit project_cycle_analytics_path(project)
        wait_for_requests
        find(value_stream_selector).click
        click_button(value_stream_name, match: :first)
        wait_for_requests
      end

      it 'displays data' do
        expect(page).to have_content(value_stream_name)
        expect(page).to have_selector(duration_chart_selector)
        expect(page).to have_selector(metrics_selector)

        metrics_tiles = page.find(metrics_selector)
        expect(metrics_tiles).to have_content('Commit')
        expect(metrics_tiles).to have_content('Deploy')
        expect(metrics_tiles).to have_content('Deployment Frequency')
        expect(metrics_tiles).to have_content('New Issue')
      end
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
