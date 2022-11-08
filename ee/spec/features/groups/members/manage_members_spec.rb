# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members', :saas, :js do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include SubscriptionPortalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:user3) { create(:user, name: 'Peter Parker') }
  let_it_be(:group) { create(:group) }
  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }

  context 'with overage modal concerns' do
    let_it_be(:premium_plan) { create(:premium_plan) }

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

        page.within find_member_row(user2) do
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

    context 'when adding a member to a free group' do
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

          invite_member([user2.name, user3.name], role: 'Developer', refresh: false)

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
          expect(page).to have_content("Your subscription includes 1 seat. If you continue, the #{group.name} " \
                                       "group will have 2 seats in use and will be billed for the overage. Learn more.")

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

    def add_user_by_name(name, role)
      visit group_group_members_path(group)

      invite_member(name, role: role, refresh: false)
    end
  end

  context 'with banned members' do
    let_it_be(:sub_group) { create(:group, parent: group) }

    let(:licensed_feature_available) { true }
    let(:owner) { user1 }
    let(:group_member) { user2 }
    let(:subgroup_member) { user3 }

    before do
      stub_licensed_features(unique_project_download_limit: licensed_feature_available)

      create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan)
      create(:namespace_ban, namespace: group, user: group_member)
      create(:namespace_ban, namespace: group, user: subgroup_member)

      group.add_owner(owner)
      group.add_developer(group_member)
      sub_group.add_developer(subgroup_member)

      sign_in(user1)
    end

    it 'owner can unban banned users' do
      visit group_group_members_path(group)

      click_on 'Banned'

      expect(all_rows.count).to eq 2

      page.within find_member_row(group_member) do
        click_button 'Unban'
      end
      expect(page).to have_content('User was successfully unbanned.')

      page.within find_member_row(subgroup_member) do
        click_button 'Unban'
      end
      expect(page).to have_content('User was successfully unbanned.')

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

  context 'with free user limit', :saas do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when at free user limit' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_enforcement_limit: 1)
        group = create(:group_with_plan, :private, plan: :free_plan)
        user = create(:user)
        group.add_owner(user)

        sign_in(user)

        visit group_group_members_path(group)

        click_on 'Invite members'

        page.within invite_modal_selector do
          expect(page).to have_content "You've reached your"
          expect(page).to have_content 'To invite new users to this namespace, you must remove existing users.'
        end
      end
    end

    context 'when close to free user limit on new namespace' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_limit: 3)
        stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)
        group = create(:group_with_plan, :private, plan: :free_plan)
        user = create(:user)
        group.add_owner(user)

        sign_in(user)

        visit group_group_members_path(group)

        click_on 'Invite members'

        page.within invite_modal_selector do
          expect(page).to have_content 'You only have space for'
          expect(page).to have_content 'To get more members an owner of the group can'
        end
      end
    end
  end
end
