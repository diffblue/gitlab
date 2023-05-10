# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits iteration cadence', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:guest_user) { create(:group_member, :guest, user: create(:user), group: group).user }
  let_it_be(:cadence) { create(:iterations_cadence, group: group, description: 'an example iteration cadence', duration_in_weeks: 3, iterations_in_advance: 2) }

  dropdown_selector = '[data-testid="actions-dropdown"]'

  context 'with license' do
    before do
      stub_licensed_features(iterations: true)
    end

    context 'as authorized user', time_travel_to: '2023-05-04' do
      before do
        sign_in(user)

        allow(Time.zone).to receive(:name).and_return(ActiveSupport::TimeZone["UTC"].name)
        allow(Time.zone).to receive(:utc_offset).and_return(ActiveSupport::TimeZone["UTC"].utc_offset)

        visit edit_group_iteration_cadence_path(cadence.group, id: cadence.id)
      end

      it 'displays the configured timezone used to rollover issues' do
        expect(page.find("[data-testid='cadence-rollover-group']"))
          .to have_content("Incomplete issues will be added to the next iteration at midnight, [UTC 0] UTC.")
      end

      context 'when a timezone is other than UTC is used' do
        before do
          allow(Time.zone).to receive(:name).and_return(ActiveSupport::TimeZone["Hawaii"].name)
          allow(Time.zone).to receive(:utc_offset).and_return(ActiveSupport::TimeZone["Hawaii"].utc_offset)

          visit edit_group_iteration_cadence_path(cadence.group, id: cadence.id)
        end

        it 'displays the configured timezone used to rollover issues' do
          expect(page.find("[data-testid='cadence-rollover-group']"))
            .to have_content("Incomplete issues will be added to the next iteration at midnight, [UTC-10] Hawaii.")
        end
      end

      it 'prefills fields and allows updating values' do
        aggregate_failures do
          expect(title_input.value).to eq(cadence.title)
          expect(description_input.value).to eq(cadence.description)
          expect(start_date_input.value).to have_content(cadence.start_date)
        end

        updated_title = 'Updated cadence title'

        fill_in('Title', with: updated_title)
        click_button('Save changes')

        expect(page).to have_content(updated_title)
      end
    end

    context 'as guest user' do
      before do
        sign_in(guest_user)
      end

      it 'does not show edit dropdown' do
        visit group_iteration_cadences_path(cadence.group)

        expect(page).to have_content(cadence.title)
        expect(page).not_to have_selector(dropdown_selector)
      end

      it 'redirects to list page when loading edit cadence page' do
        visit edit_group_iteration_cadence_path(cadence.group, id: cadence.id)

        # vue-router has trailing slash which apparently cannot be removed
        # until version 4 - https://github.com/vuejs/vue-router/issues/2945
        expect(page).to have_current_path("#{group_iteration_cadences_path(cadence.group)}/")
      end

      it 'redirects to list page when loading new cadence page' do
        visit new_group_iteration_cadence_path(cadence.group)

        # vue-router has trailing slash which apparently cannot be removed
        # until version 4 - https://github.com/vuejs/vue-router/issues/2945
        expect(page).to have_current_path("#{group_iteration_cadences_path(cadence.group)}/")
      end
    end

    def title_input
      page.find('#cadence-title')
    end

    def description_input
      page.find('#cadence-description')
    end

    def start_date_input
      page.find('#cadence-start-date')
    end
  end
end
