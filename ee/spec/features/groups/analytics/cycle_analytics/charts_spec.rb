# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Value stream analytics charts', :js do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:group2) { create(:group, name: 'CA-bad-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }
  let_it_be(:group_label1) { create(:group_label, group: group) }
  let_it_be(:group_label2) { create(:group_label, group: group) }
  let_it_be(:label) { create(:group_label, group: group2) }

  empty_state_selector = '[data-testid="vsa-empty-state"]'

  3.times do |i|
    let_it_be("issue_#{i}".to_sym) { create(:issue, title: "New Issue #{i}", project: project, created_at: 2.days.ago) }
  end

  def toggle_more_options(stage)
    stage.hover

    stage.find('[data-testid="more-actions-toggle"]').click
  end

  before_all do
    group.add_owner(user)
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    sign_in(user)
  end

  shared_examples 'has the empty state' do
    it 'renders the empty state' do
      expect(page).to have_selector(empty_state_selector)
      expect(page).to have_text(s_('CycleAnalytics|Custom value streams to measure your DevSecOps lifecycle'))
    end
  end

  shared_examples 'has the duration chart' do
    it 'displays data for all stages on the overview' do
      page.within('[data-testid="vsa-path-navigation"]') do
        click_button "Overview"
      end

      expect(page).to have_text("Total time")
    end

    it 'displays data for a specific stage when selected' do
      page.within('[data-testid="vsa-path-navigation"]') do
        click_button "Issue"
      end

      expect(page).to have_text("Stage time: Issue")
    end
  end

  shared_examples 'has the tasks by type chart' do
    context 'with data available' do
      filters_selector = '.js-tasks-by-type-chart-filters'

      before do
        group_label1 = create(:group_label, group: selected_group)
        group_label2 = create(:group_label, group: selected_group)

        mr_issue = create(:labeled_issue, created_at: 5.days.ago, project: create(:project, group: selected_group), labels: [group_label2])
        create(:merge_request, iid: mr_issue.id, created_at: 3.days.ago, source_project: selected_project, labels: [group_label1, group_label2])

        3.times do |i|
          create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: selected_group), labels: [group_label1])
          create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: selected_group), labels: [group_label2])
        end

        select_group(selected_group)
      end

      it 'displays the chart' do
        expect(page).to have_text(s_('CycleAnalytics|Type of work'))

        expect(page).to have_text(s_('CycleAnalytics|Tasks by type'))
      end

      it 'has 2 labels selected' do
        expect(page).to have_text('Showing Issues and 2 labels')
      end

      it 'has chart filters' do
        expect(page).to have_css(filters_selector)
      end

      it 'can update the filters' do
        page.within filters_selector do
          find('.dropdown-toggle').click
          first_selected_label = all('[data-testid="type-of-work-filters-label"] .dropdown-item.active').first
          first_selected_label.click
        end

        expect(page).to have_text('Showing Issues and 1 label')

        page.within filters_selector do
          find('.dropdown-toggle').click
          find('[data-testid="type-of-work-filters-subject"] label', text: 'Merge Requests').click
        end

        expect(page).to have_text('Showing Merge Requests and 1 label')
      end
    end

    context 'no data available' do
      before do
        select_group(selected_group)
      end

      it 'shows the no data available message' do
        expect(page).to have_text(s_('CycleAnalytics|Type of work'))

        expect(page).to have_text(_('There is no data available. Please change your selection.'))
      end
    end
  end

  describe 'Duration chart', :js do
    context 'use_vsa_aggregated_tables feature flag off' do
      before do
        stub_feature_flags(use_vsa_aggregated_tables: false)

        select_group(group)
      end

      it_behaves_like 'has the duration chart'
    end

    context 'use_vsa_aggregated_tables feature flag on' do
      context 'with no value streams' do
        before do
          select_group(group, empty_state_selector)
        end

        it_behaves_like 'has the empty state'
      end

      context 'with a value stream' do
        before do
          select_group(group_with_value_stream)
        end

        it_behaves_like 'has the duration chart'
      end
    end
  end

  describe 'Tasks by type chart', :js do
    before do
      stub_licensed_features(cycle_analytics_for_groups: true, type_of_work_analytics: true)

      project.add_maintainer(user)

      sign_in(user)
    end

    context 'type_of_work_analytics enabled' do
      context 'use_vsa_aggregated_tables feature flag off' do
        before do
          stub_feature_flags(use_vsa_aggregated_tables: false)
        end

        it_behaves_like 'has the tasks by type chart'
      end

      context 'use_vsa_aggregated_tables feature flag on' do
        context 'with no value streams' do
          before do
            select_group(group, empty_state_selector)
          end

          it_behaves_like 'has the empty state'
        end

        context 'with a value stream' do
          before do
            create(:cycle_analytics_group_value_stream, group: group, name: 'First value stream')
          end

          it_behaves_like 'has the tasks by type chart'
        end
      end
    end
  end
end
