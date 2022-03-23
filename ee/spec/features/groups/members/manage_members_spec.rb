# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members', :saas, :js do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:user3) { create(:user, name: 'Peter Parker') }
  let_it_be(:group) { create(:group) }

  let(:premium_plan) { create(:premium_plan) }

  shared_examples "adding one user doesn't trigger an overage modal" do
    it do
      group.add_owner(user1)
      add_user_by_name(user2.name, 'Developer')

      expect(page).not_to have_content("You are about to incur additional charges")
      wait_for_requests

      page.refresh

      page.within(second_row) do
        expect(page).to have_content(user2.name)
        expect(page).to have_button('Developer')
      end
    end
  end

  before do
    sign_in(user1)
    stub_application_setting(check_namespace_plan: true)
  end

  context 'adding a member to a free group' do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: nil)
    end

    it_behaves_like "adding one user doesn't trigger an overage modal"
  end

  context 'when adding a member to a premium group' do
    context 'when there is one free space in the subscription' do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 2, seats_in_use: 1)
      end

      it_behaves_like "adding one user doesn't trigger an overage modal"

      it 'adding two users triggers overage modal', :aggregate_failures do
        group.add_owner(user1)
        visit group_group_members_path(group)

        click_on 'Invite members'

        page.within '[data-testid="invite-modal"]' do
          add_user_to_input(user2.name)
          add_user_to_input(user3.name)

          choose_options('Developer', nil)

          click_button 'Invite'
        end

        expect(page).to have_content("You are about to incur additional charges")
        expect(page).to have_content("Your subscription includes 2 seats. If you continue, the #{group.name} group will have 3 seats in use and will be billed for the overage. Learn more.")
      end
    end

    context 'when modal is shown' do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 1)
      end

      it 'invites a member to a group if confirmed', :aggregate_failures do
        group.add_owner(user1)
        add_user_by_name(user2.name, 'Developer')

        expect(page).to have_content("You are about to incur additional charges")
        expect(page).to have_content("Your subscription includes 1 seat. If you continue, the #{group.name} group will have 2 seats in use and will be billed for the overage. Learn more.")

        click_button 'Continue'

        page.refresh

        page.within(second_row) do
          expect(page).to have_content(user2.name)
          expect(page).to have_button('Developer')
        end
      end

      it 'get back to initial modal if not confirmed', :aggregate_failures do
        group.add_owner(user1)
        add_user_by_name(user2.name, 'Developer')

        expect(page).to have_content("You are about to incur additional charges")
        expect(page).to have_content("Your subscription includes 1 seat. If you continue, the #{group.name} group will have 2 seats in use and will be billed for the overage. Learn more.")

        click_button 'Back'

        expect(page).to have_content("You're inviting members to the #{group.name} group.")

        click_button 'Cancel'

        expect(page).not_to have_content(user2.name)
        expect(page).not_to have_button('Developer')
      end
    end
  end

  def add_user_by_name(name, role)
    visit group_group_members_path(group)

    click_on 'Invite members'

    page.within '[data-testid="invite-modal"]' do
      add_user_to_input(name)
      choose_options(role, nil)

      click_button 'Invite'
    end
  end

  def add_user_to_input(name)
    find('[data-testid="members-token-select-input"]').set(name)

    wait_for_requests
    click_button name
  end
end
