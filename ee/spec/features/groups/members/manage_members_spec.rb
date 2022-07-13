# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members', :saas, :js do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers
  include SubscriptionPortalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:user3) { create(:user, name: 'Peter Parker') }
  let_it_be(:group) { create(:group) }

  let(:premium_plan) { create(:premium_plan) }
  let(:ultimate_plan) { create(:ultimate_plan) }

  shared_examples "adding one user with a given role doesn't trigger an overage modal" do |role|
    it do
      group.add_owner(user1)
      add_user_by_name(user2.name, role)

      expect(page).not_to have_content("You are about to incur additional charges")
      wait_for_requests

      page.refresh

      page.within(second_row) do
        expect(page).to have_content(user2.name)
        expect(page).to have_button(role)
      end
    end
  end

  shared_examples "shows an overage for one Developer added and invites them to a group if confirmed" do
    it do
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
  end

  before do
    sign_in(user1)
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)
    stub_subscription_request_seat_usage(true)
  end

  context 'adding a member to a free group' do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: nil)
    end

    it_behaves_like "adding one user with a given role doesn't trigger an overage modal", 'Developer'
  end

  context 'when adding a member to a premium group' do
    context 'when there is one free space in the subscription' do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 2, seats_in_use: 1)
      end

      it_behaves_like "adding one user with a given role doesn't trigger an overage modal", 'Developer'

      it 'adding two users triggers overage modal', :aggregate_failures do
        group.add_owner(user1)
        visit group_group_members_path(group)

        click_on 'Invite members'

        page.within invite_modal_selector do
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

      it_behaves_like "shows an overage for one Developer added and invites them to a group if confirmed"

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

  context 'when adding a member to a ultimate group with no places left' do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan, seats: 1, seats_in_use: 1)
    end

    it_behaves_like "shows an overage for one Developer added and invites them to a group if confirmed"
    it_behaves_like "adding one user with a given role doesn't trigger an overage modal", 'Guest'
  end

  context 'when adding to a group not eligible for reconciliation', :aggregate_failures do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan, seats: 1, seats_in_use: 1)
      stub_subscription_request_seat_usage(false)
    end

    it_behaves_like "adding one user with a given role doesn't trigger an overage modal", 'Developer'
  end

  describe 'banned members' do
    let(:licensed_feature_available) { true }

    before do
      stub_licensed_features(unique_project_download_limit: licensed_feature_available)

      create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan)
      create(:namespace_ban, namespace: group, user: user2)

      group.add_owner(user1)
      group.add_developer(user2)
    end

    it 'owner can unban banned users' do
      visit group_group_members_path(group)

      click_on 'Banned'

      page.within(first_row) do
        expect(page).to have_content(user2.name)
      end

      click_button 'Unban'

      expect(page).not_to have_content('Banned')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
      end

      it 'owner cannot see banned users' do
        visit group_group_members_path(group)

        expect(page).not_to have_content('Banned')
      end
    end

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it 'owner cannot see banned users' do
        visit group_group_members_path(group)

        expect(page).not_to have_content('Banned')
      end
    end
  end

  def add_user_by_name(name, role)
    visit group_group_members_path(group)

    click_on 'Invite members'

    page.within invite_modal_selector do
      add_user_to_input(name)
      choose_options(role, nil)

      click_button 'Invite'
    end
  end

  def add_user_to_input(name)
    find(member_dropdown_selector).set(name)

    wait_for_requests
    click_button name
  end
end
