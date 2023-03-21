# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members', :saas, :js, feature_category: :subgroups do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers
  include SubscriptionPortalHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:user3) { create(:user, name: 'Peter Parker') }
  let_it_be(:enterprise_user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }
  let_it_be(:ultimate_plan, reload: true) { create(:ultimate_plan) }

  context 'with overage modal concerns' do
    let_it_be(:premium_plan) { create(:premium_plan) }

    shared_examples "adding one user by email with a given role doesn't trigger an overage modal" do |role|
      it "adding one user with a given role doesn't trigger an overage modal" do
        group.add_owner(user1)
        add_user_by_email(role)

        wait_for_requests
        expect(page).not_to have_content(s_('MembersOverage|You are about to incur additional charges'))

        page.refresh

        expect(page).to have_content(_('Invited'))
      end
    end

    shared_examples "adding one user with a given role doesn't trigger an overage modal" do |role|
      it "adding one user with a given role doesn't trigger an overage modal" do
        group.add_owner(user1)
        add_user_by_name(user2.name, role)

        wait_for_requests
        expect(page).not_to have_content(s_('MembersOverage|You are about to incur additional charges'))

        page.refresh

        page.within(second_row) do
          expect(page).to have_content(user2.name)
          expect(page).to have_button(role)
        end
      end
    end

    shared_examples "shows an overage modal when adding one user with a given role" do |role|
      it "shows a modal and invites them to a group if confirmed" do
        group.add_owner(user1)
        add_user_by_name(user2.name, role)

        message = ns_('MembersOverage|Your subscription includes %d seat.', 'MembersOverage|Your subscription includes %d seats.', 1) % 1
        info = format(ns_('MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.', 'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.', 2), groupName: group.name, quantity: 2)

        expect(page).to have_content(s_('MembersOverage|You are about to incur additional charges'))
        expect(page).to have_content(message)
        expect(page).to have_content(info)

        click_button _('Continue')

        wait_for_requests

        page.refresh

        page.within find_member_row(user2) do
          expect(page).to have_button(role)
        end
      end
    end

    shared_examples "adding user by email with a given role" do |role|
      it "shows a modal and invites them to a group if confirmed" do
        group.add_owner(user1)
        add_user_by_email(role)

        message = ns_('MembersOverage|Your subscription includes %d seat.', 'MembersOverage|Your subscription includes %d seats.', 1) % 1
        info = format(ns_('MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.', 'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.', 2), groupName: group.name, quantity: 2)

        expect(page).to have_content(s_('MembersOverage|You are about to incur additional charges'))
        expect(page).to have_content(message)
        expect(page).to have_content(info)

        click_button _('Continue')

        wait_for_requests

        page.refresh

        expect(page).to have_content(_('Invited'))
      end
    end

    before do
      sign_in(user1)
      stub_signing_key
      stub_application_setting(check_namespace_plan: true)
      stub_reconciliation_request(true)
    end

    context 'when adding a member to a free group' do
      before do
        stub_reconciliation_request(false)
        create(:gitlab_subscription, namespace: group, hosted_plan: nil)
      end

      include_examples 'adding one user with a given role doesn\'t trigger an overage modal', 'Developer'
    end

    context 'when adding a member to a premium group' do
      context 'when there is no free spaces in the subscription' do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 1)
        end

        include_examples 'shows an overage modal when adding one user with a given role', 'Guest'
        include_examples 'shows an overage modal when adding one user with a given role', 'Developer'

        include_examples 'adding user by email with a given role', 'Guest'
        include_examples 'adding user by email with a given role', 'Developer'
      end

      context 'when there is one free space in the subscription' do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 2, seats_in_use: 1)
        end

        include_examples 'adding one user with a given role doesn\'t trigger an overage modal', 'Developer'

        it 'adding two users triggers overage modal', :aggregate_failures do
          group.add_owner(user1)
          visit group_group_members_path(group)

          invite_member([user2.name, user3.name], role: 'Developer')

          message = ns_('MembersOverage|Your subscription includes %d seat.', 'MembersOverage|Your subscription includes %d seats.', 2) % 2
          info = format(ns_('MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.', 'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.', 3), groupName: group.name, quantity: 3)

          expect(page).to have_content(s_('MembersOverage|You are about to incur additional charges'))
          expect(page).to have_content(message)
          expect(page).to have_content(info)
        end
      end

      context 'when modal is shown' do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 1)
        end

        it 'get back to initial modal if not confirmed', :aggregate_failures do
          group.add_owner(user1)
          add_user_by_name(user2.name, 'Developer')

          message = ns_('MembersOverage|Your subscription includes %d seat.', 'MembersOverage|Your subscription includes %d seats.', 1) % 1
          info = format(ns_('MembersOverage|If you continue, the %{groupName} group will have %{quantity} seat in use and will be billed for the overage.', 'MembersOverage|If you continue, the %{groupName} group will have %{quantity} seats in use and will be billed for the overage.', 2), groupName: group.name, quantity: 2)

          expect(page).to have_content(s_('MembersOverage|You are about to incur additional charges'))
          expect(page).to have_content(message)
          expect(page).to have_content(info)

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

      include_examples 'adding one user with a given role doesn\'t trigger an overage modal', 'Guest'
      include_examples 'shows an overage modal when adding one user with a given role', 'Developer'

      include_examples 'adding one user by email with a given role doesn\'t trigger an overage modal', 'Guest'
      include_examples 'adding user by email with a given role', 'Developer'
    end

    context 'when adding a member to a ultimate group that alerady has an overage' do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan, seats: 1, seats_in_use: 2)
      end

      include_examples 'shows an overage modal when adding one user with a given role', 'Developer'
      include_examples 'adding one user by email with a given role doesn\'t trigger an overage modal', 'Guest'
    end

    context 'when adding to a group not eligible for reconciliation', :aggregate_failures do
      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan, seats: 1, seats_in_use: 1)
        stub_reconciliation_request(false)
      end

      include_examples 'adding one user with a given role doesn\'t trigger an overage modal', 'Developer'
    end

    def add_user_by_name(name, role)
      visit group_group_members_path(group)

      invite_member(name, role: role)
    end

    def add_user_by_email(role)
      visit group_group_members_path(group)

      invite_member_by_email(role)
    end
  end

  context 'with enterprise users' do
    before do
      sign_in(user1)
    end

    it 'can disable two-factor authentication', :js do
      group.add_owner(user1)
      group.add_developer(enterprise_user)

      visit group_group_members_path(group)

      page.within find_member_row(enterprise_user) do
        show_actions
        click_button s_('Members|Disable two-factor authentication')
      end

      within_modal do
        click_button _('Disable')
      end

      wait_for_requests

      page.within find_member_row(enterprise_user) do
        show_actions
        expect(page).not_to have_button(s_('Members|Disable two-factor authentication'))
      end
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

  describe 'banning' do
    let(:licensed_feature_available) { true }
    let(:owner) { user1 }
    let(:current_user) { owner }
    let(:group_member) { user2 }

    before do
      stub_licensed_features(unique_project_download_limit: licensed_feature_available)

      group.add_owner(owner)
      group.add_developer(group_member)

      sign_in(current_user)
    end

    it 'allows owner to ban a member' do
      visit group_group_members_path(group)

      expect(all_rows.count).to eq 2

      show_actions_for_username(group_member)
      click_button 'Ban member'

      expect(page).to have_content('User was successfully banned.')

      click_on 'Banned'

      expect(all_rows.count).to eq 1
    end

    shared_examples 'action is not available' do
      it 'action is not available' do
        visit group_group_members_path(group)

        show_actions_for_username(group_member)

        expect(page).not_to have_content('Ban member')
      end
    end

    context 'when non-owner' do
      let(:current_user) { group_member }

      it_behaves_like 'action is not available'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
      end

      it_behaves_like 'action is not available'
    end

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it_behaves_like 'action is not available'
    end
  end

  context 'with free user limit', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan, name: 'free-user-limit-group') }

    before_all do
      group.add_owner(user)
    end

    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
      stub_feature_flags(preview_free_user_cap: false)
    end

    context 'when previewing free user limit' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_limit: 1)
        stub_ee_application_setting(dashboard_enforcement_limit: 1)
        stub_feature_flags(preview_free_user_cap: true)
        stub_feature_flags(free_user_cap: false)

        sign_in(user)

        visit group_group_members_path(group)

        click_on _('Invite members')

        page.within invite_modal_selector do
          expect(page).to have_content "Your top-level group free-user-limit-group is over the 1 user limit."
          expect(page).to have_content 'GitLab will enforce this limit in the future.'
        end
      end
    end

    context 'when at free user limit' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_enforcement_limit: 1)

        sign_in(user)

        visit group_group_members_path(group)

        click_on _('Invite members')

        page.within invite_modal_selector do
          expect(page).to have_content "You've reached your"
          expect(page).to have_content 'To invite new users to this top-level group, you must remove existing users.'
        end
      end
    end

    context 'when close to free user limit on new top-level group' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_limit: 4)
        stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)

        sign_in(user)

        visit group_group_members_path(group)

        invite_member(create(:user).name)

        click_on _('Invite members')

        page.within invite_modal_selector do
          expect(page).to have_content 'You only have space for 2'
          expect(page).to have_content 'To get more members an owner of the group can'

          click_on _('Cancel')
        end

        invite_member(create(:user).name)

        click_on _('Invite members')

        page.within invite_modal_selector do
          expect(page).to have_content 'You only have space for 1'
          expect(page).to have_content 'To get more members an owner of the group can'
        end
      end
    end
  end

  context 'with an active trial', :saas do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :private, name: 'active-trial-group') }

    before do
      create(:gitlab_subscription, :active_trial, namespace: group)

      stub_ee_application_setting(dashboard_limit_enabled: true)

      group.add_owner(user)

      sign_in(user)
    end

    it 'shows the active trial unlimited members alert' do
      visit group_group_members_path(group)

      click_on _('Invite members')

      page.within invite_modal_selector do
        expect(page).to have_content 'Add unlimited members with your trial'
        expect(page).to have_content 'During your trial, you can invite as many members to active-trial-group'
        expect(page).to have_link(text: 'upgrade to a paid plan', href: group_billings_path(group.root_ancestor))
        expect(page).to have_content 'Cancel'
      end
    end
  end
end
