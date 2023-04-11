# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Multiple value streams', :js, feature_category: :value_stream_management do
  include CycleAnalyticsHelpers

  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }
  let_it_be(:sub_group) { create(:group, name: 'CA-sub-group', parent: group) }
  let_it_be(:group_label1) { create(:group_label, group: group) }
  let_it_be(:group_label2) { create(:group_label, group: group) }
  let_it_be(:user) do
    create(:user).tap do |u|
      group.add_owner(u)
      project.add_maintainer(u)
    end
  end

  let(:extended_form_fields_selector) { '[data-testid="extended-form-fields"]' }
  let(:preset_selector) { '[data-testid="vsa-preset-selector"]' }
  let(:empty_state_selector) { '[data-testid="vsa-empty-state"]' }

  3.times do |i|
    let_it_be("issue_#{i}".to_sym) { create(:issue, title: "New Issue #{i}", project: project, created_at: 2.days.ago) }
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true, type_of_work_analytics: true)

    sign_in(user)
  end

  def path_nav_elem
    page.find('[data-testid="vsa-path-navigation"]')
  end

  def click_action_button(action, index)
    page.find("[data-testid='stage-action-#{action}-#{index}']").click
  end

  def reload_value_stream
    click_button 'Reload page'
  end

  def create_and_select_value_stream(name, with_aggregation = true)
    create_custom_value_stream(name)

    return unless with_aggregation

    reload_value_stream
    select_value_stream(name)
  end

  shared_examples 'create a value stream' do |custom_value_stream_name|
    before do
      toggle_value_stream_dropdown
      page.find_button(_('Create new Value Stream')).click
    end

    it 'includes additional form fields' do
      expect(page).to have_selector(extended_form_fields_selector)
    end

    it 'can create a value stream' do
      save_value_stream(custom_value_stream_name)

      expect(page).to have_text(_("'%{name}' Value Stream created") % { name: custom_value_stream_name })
    end

    it 'can create a value stream with only custom stages' do
      page.find(preset_selector).choose("Create from no template")

      fill_in_custom_stage_fields
      save_value_stream(custom_value_stream_name)

      expect(page).to have_text(_("'%{name}' Value Stream created") % { name: custom_value_stream_name })
    end

    it 'can create a value stream with a custom stage and hidden defaults' do
      add_custom_stage_to_form
      add_custom_label_stage_to_form

      # Hide some default stages
      click_action_button('hide', 5)
      click_action_button('hide', 3)
      click_action_button('hide', 1)

      save_value_stream(custom_value_stream_name)

      expect(page).to have_text(_("'%{name}' Value Stream created") % { name: custom_value_stream_name })
      expect(path_nav_elem).to have_text("Cool custom stage - name")
    end
  end

  shared_examples 'update a value stream' do |custom_value_stream_name, with_aggregation|
    before do
      select_group(group)

      create_and_select_value_stream(custom_value_stream_name, with_aggregation)
    end

    it 'can reorder stages' do
      expect(path_nav_stage_names_without_median).to eq(["Overview", "Issue", "Plan", "Code", "Test", "Review", "Staging", "Cool custom stage - name 7"])

      page.find_button(_('Edit')).click
      # Re-arrange a few stages
      page.all("[data-testid*='stage-action-move-down-']").first.click
      page.all("[data-testid*='stage-action-move-up-']").last.click

      click_save_value_stream_button
      wait_for_requests

      expect(path_nav_stage_names_without_median).to eq(["Overview", "Plan", "Issue", "Code", "Test", "Review", "Cool custom stage - name 7", "Staging"])
    end

    context 'updating' do
      before do
        page.find_button(_('Edit')).click
      end

      it 'includes additional form fields' do
        expect(page).to have_selector(extended_form_fields_selector)
        expect(page).to have_button("Save value stream")
      end

      it 'can update the value stream name' do
        edited_name = "Edit new value stream"
        fill_in 'create-value-stream-name', with: edited_name

        click_save_value_stream_button
        wait_for_requests

        expect(page).to have_text(_("'%{name}' Value Stream saved") % { name: edited_name })
      end

      it 'can add and remove custom stages' do
        add_custom_stage_to_form
        add_custom_label_stage_to_form

        click_save_value_stream_button
        wait_for_requests

        expect(path_nav_elem).to have_text("Cool custom stage - name")

        page.find_button(_('Edit')).click

        # Delete the custom stages, delete the last one first since the list gets reordered after a deletion
        click_action_button('remove', 7)
        click_action_button('remove', 6)

        # re-order some stages
        page.all("[data-testid*='stage-action-move-down-']").first.click
        page.all("[data-testid*='stage-action-move-up-']").last.click

        click_save_value_stream_button
        wait_for_requests

        expect(path_nav_elem).not_to have_text("Cool custom stage - name")
      end

      it 'can hide and restore default stages' do
        click_action_button('hide', 5)
        click_action_button('hide', 4)
        click_action_button('hide', 3)

        click_save_value_stream_button
        wait_for_requests

        expect(page).to have_text(_("'%{name}' Value Stream saved") % { name: custom_value_stream_name })
        expect(path_nav_elem).not_to have_text("Staging")
        expect(path_nav_elem).not_to have_text("Review")
        expect(path_nav_elem).not_to have_text("Test")

        click_button(_('Edit'))
        click_action_button('restore', 0)

        click_save_value_stream_button
        wait_for_requests

        expect(page).to have_text(_("'%{name}' Value Stream saved") % { name: custom_value_stream_name })
        expect(path_nav_elem).to have_text("Test")
      end
    end
  end

  shared_examples 'delete a value stream' do |custom_value_stream_name|
    before do
      value_stream = create(:cycle_analytics_value_stream, name: custom_value_stream_name, namespace: group)
      create(:cycle_analytics_stage, value_stream: value_stream)

      select_group(group)
    end

    it 'can delete a value stream' do
      select_value_stream(custom_value_stream_name)

      toggle_value_stream_dropdown

      page.find_button(_('Delete %{name}') % { name: custom_value_stream_name }).click
      page.find_button(_('Delete')).click
      wait_for_requests

      expect(page).to have_text(_("'%{name}' Value Stream deleted") % { name: custom_value_stream_name })
    end
  end

  shared_examples 'create group value streams' do |with_aggregation|
    name = 'group value stream'

    before do
      select_group(group)
    end

    it_behaves_like 'create a value stream', name
    it_behaves_like 'update a value stream', name, with_aggregation
    it_behaves_like 'delete a value stream', name
  end

  shared_examples 'create sub group value streams' do |with_aggregation|
    name = 'sub group value stream'

    before do
      select_group(sub_group)
    end

    it_behaves_like 'create a value stream', name
    it_behaves_like 'update a value stream', name, with_aggregation
    it_behaves_like 'delete a value stream', name
  end

  context 'without a value stream' do
    before do
      select_group(group, empty_state_selector)
    end

    it 'renders the empty state' do
      expect(page).to have_text(s_('CycleAnalytics|Custom value streams to measure your DevSecOps lifecycle'))
    end

    it 'can navigate to the create value stream form' do
      page.find('[data-testid="create-value-stream-button"]').click

      expect(page).to have_selector('[data-testid="value-stream-form-modal"]')
    end
  end

  context 'with a value stream' do
    context 'without an aggregation created' do
      before do
        create(:cycle_analytics_value_stream, namespace: group, name: 'default')
        select_group(group)
      end

      it 'renders the aggregating status banner' do
        expect(page).to have_text(s_('CycleAnalytics|Data is collecting and loading.'))
      end

      it 'displays the value stream once an aggregation is run' do
        create_value_stream_aggregation(group)

        reload_value_stream

        expect(page).not_to have_button(_('Reload page'))
        expect(page).to have_text('Last updated less than a minute ago')
      end
    end

    context 'with an aggregation created' do
      before do
        create_value_stream_aggregation(group)
        create_value_stream_aggregation(sub_group)

        # ensure we have a value stream already available
        create(:cycle_analytics_value_stream, namespace: group, name: 'default')
        create(:cycle_analytics_value_stream, namespace: sub_group, name: 'default')
      end

      it_behaves_like 'create group value streams', true
      it_behaves_like 'create sub group value streams', true
    end
  end
end
