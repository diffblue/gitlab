# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Value stream analytics charts', :js, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:group2) { create(:group, name: 'CA-bad-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }
  let_it_be(:group_label1) { create(:group_label, group: group) }
  let_it_be(:group_label2) { create(:group_label, group: group) }
  let_it_be(:label) { create(:group_label, group: group2) }

  let_it_be(:custom_value_stream_name) { "New created value stream" }

  let_it_be(:value_stream) do
    create(:cycle_analytics_value_stream, namespace: group, name: custom_value_stream_name, stages: [
             create(:cycle_analytics_stage, namespace: group, name: "Issue", relative_position: 1, start_event_identifier: :issue_created, end_event_identifier: :issue_closed),
             create(:cycle_analytics_stage, namespace: group, name: "Code", relative_position: 2, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged),
             create(:cycle_analytics_stage, namespace: group, name: "Milestone Plan", relative_position: 3, start_event_identifier: :issue_first_associated_with_milestone, end_event_identifier: :issue_first_added_to_board)
           ])
  end

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

  context 'Duration chart' do
    before do
      select_group_and_custom_value_stream(group, custom_value_stream_name)
    end

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

  describe 'Tasks by type chart', :js do
    let(:filters_selector) { '.js-tasks-by-type-chart-filters' }
    let(:task_by_type_description_tooltip) { page.find('[data-testid="vsa-task-by-type-description"]') }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true, type_of_work_analytics: true)

      project.add_maintainer(user)

      sign_in(user)
    end

    context 'enabled' do
      context 'with data available' do
        before do
          mr_issue = create(:labeled_issue, created_at: 5.days.ago, project: create(:project, group: group), labels: [group_label2])
          create(:merge_request, iid: mr_issue.id, created_at: 3.days.ago, source_project: project, labels: [group_label1, group_label2])

          3.times do |i|
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [group_label1])
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [group_label2])
          end

          select_group_and_custom_value_stream(group, custom_value_stream_name)
        end

        it 'displays the chart' do
          expect(page).to have_text(s_('CycleAnalytics|Tasks by type'))
        end

        it 'has 2 labels selected' do
          task_by_type_description_tooltip.hover
          expect(page).to have_text('Shows issues and 2 labels')
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

          task_by_type_description_tooltip.hover
          expect(page).to have_text('Shows issues and 1 label')

          page.within filters_selector do
            find('.dropdown-toggle').click
            find('[data-testid="type-of-work-filters-subject"] label', text: 'Merge Requests').click
          end

          task_by_type_description_tooltip.hover
          expect(page).to have_text('Shows merge requests and 1 label')
        end
      end

      context 'no data available' do
        before do
          select_group_and_custom_value_stream(group, custom_value_stream_name)
        end

        it 'shows the no data available message' do
          expect(page).to have_text(_('There is no data available. Please change your selection.'))
        end
      end
    end
  end
end
