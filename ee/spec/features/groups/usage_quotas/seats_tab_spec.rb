# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Usage Quotas > Seats tab', :js, :saas, feature_category: :subscription_cost_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:user_from_sub_group) { create(:user) }
  let_it_be(:shared_group) { create(:group) }
  let_it_be(:shared_group_developer) { create(:user) }

  before do
    stub_feature_flags(usage_quotas_for_all_editions: false)
    stub_application_setting(check_namespace_plan: true)

    group.add_owner(user)
    group.add_maintainer(maintainer)

    sub_group.add_maintainer(user_from_sub_group)

    shared_group.add_developer(shared_group_developer)
    create(:group_group_link, { shared_with_group: shared_group, shared_group: group })

    sign_in(user)
  end

  context 'with seat usage table' do
    before do
      visit group_seat_usage_path(group)
      wait_for_requests
    end

    it 'displays correct number of users' do
      within member_table_selector do
        expect(all('tbody tr').count).to eq(4)
      end
    end

    context 'with seat usage details table' do
      it 'expands the details on click' do
        first('[data-testid="toggle-seat-usage-details"]').click

        wait_for_requests

        expect(page).to have_selector('[data-testid="seat-usage-details"]')
      end

      it 'hides the details table on click' do
        # expand the details table first
        first('[data-testid="toggle-seat-usage-details"]').click

        wait_for_requests

        # and collapse it
        first('[data-testid="toggle-seat-usage-details"]').click

        expect(page).not_to have_selector('[data-testid="seat-usage-details"]')
      end
    end
  end

  context 'when removing user' do
    before do
      visit group_seat_usage_path(group)
      wait_for_requests
    end

    context 'with a modal to confirm removal' do
      before do
        within user_to_remove_row do
          click_button 'Remove user'
        end
      end

      it 'has disabled the remove button' do
        within billable_member_modal_selector do
          expect(page).to have_button('Remove user', disabled: true)
        end
      end

      it 'enables the remove button when user enters valid username' do
        within billable_member_modal_selector do
          find('input').fill_in(with: maintainer.username)
          find('input').send_keys(:tab)

          expect(page).to have_button('Remove user', disabled: false)
        end
      end

      it 'does not enable button when user enters invalid username' do
        within billable_member_modal_selector do
          find('input').fill_in(with: 'invalid username')
          find('input').send_keys(:tab)

          expect(page).to have_button('Remove user', disabled: true)
        end
      end

      it 'does not display the error modal' do
        expect(page).not_to have_content('Cannot remove user')
      end
    end

    context 'when removing the user' do
      before do
        within user_to_remove_row do
          click_button 'Remove user'
        end
      end

      it 'shows a flash message' do
        within billable_member_modal_selector do
          find('input').fill_in(with: maintainer.username)
          find('input').send_keys(:tab)

          click_button('Remove user')
        end

        wait_for_all_requests

        within member_table_selector do
          expect(all('tbody tr').count).to eq(3)
        end

        expect(page.find('.flash-container')).to have_content('User was successfully removed')
      end

      context 'when removing a user from a sub-group' do
        it 'updates the seat table of the parent group' do
          within member_table_selector do
            expect(all('tbody tr').count).to eq(4)
          end

          visit group_group_members_path(sub_group)

          click_button('Remove member')

          within '[data-testid="remove-member-modal-content"]' do
            click_button('Remove member')
          end

          wait_for_all_requests

          visit group_seat_usage_path(group)

          wait_for_all_requests

          within member_table_selector do
            expect(all('tbody tr').count).to eq(3)
          end
        end
      end
    end

    context 'when cannot remove the user' do
      let(:shared_user_row) do
        within member_table_selector do
          find('tr', text: shared_group_developer.name)
        end
      end

      it 'displays an error modal' do
        within shared_user_row do
          click_button 'Remove user'
        end

        expect(page).to have_content('Cannot remove user')
      end
    end
  end

  context 'when removing a user when the namespace is in read_only state' do
    let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
      stub_feature_flags(free_user_cap: true)

      # group_seat_usage_path does some admin_group_member check then
      # redirects to the below path where we only check read.
      # This is strangely more restrictive then going to the
      # usage_quotas controller directly with an anchor...so we'll
      # just do that since admin_group_member is prevented in
      # read_only mode.
      visit group_usage_quotas_path(group, anchor: 'seats-quota-tab')

      wait_for_requests
    end

    it 'shows a flash message' do
      within member_table_selector do
        expect(all('tbody tr').count).to eq(3)
      end

      within user_to_remove_row do
        click_button 'Remove user'
      end

      within billable_member_modal_selector do
        find('input').fill_in(with: maintainer.username)
        find('input').send_keys(:tab)

        click_button('Remove user')
      end

      wait_for_all_requests

      within member_table_selector do
        expect(all('tbody tr').count).to eq(2)
      end

      expect(page.find('.flash-container')).to have_content('User was successfully removed')
    end
  end

  def billable_member_modal_selector
    '[data-testid="remove-billable-member-modal"]'
  end

  def member_table_selector
    '[data-testid="table"]'
  end

  def user_to_remove_row
    within member_table_selector do
      find('tr', text: maintainer.name)
    end
  end
end
