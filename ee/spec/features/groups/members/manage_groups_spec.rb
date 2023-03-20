# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage groups', :js, :saas, feature_category: :subgroups do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let(:group) { create(:group) }
  let(:group_to_add) { create(:group) }

  let(:premium_plan) { create(:premium_plan) }
  let(:ultimate_plan) { create(:ultimate_plan) }

  shared_examples 'adds group without validation error' do
    it_behaves_like "doesn't trigger an overage modal when adding a group with a given role", 'Maintainer'
  end

  shared_examples 'inviting group fails with allowed email domain error' do
    specify do
      group.add_owner(user)
      group_to_add.add_owner(user)

      visit group_group_members_path(group)
      add_group(group_to_add.name, 'Maintainer')

      expect(page).to have_content('Invited group allowed email domains must contain a subset of the'\
        ' allowed email domains of the root ancestor group')
    end
  end

  shared_examples "doesn't trigger an overage modal when adding a group with a given role" do |role|
    specify do
      group.add_owner(user)
      group_to_add.add_owner(user)

      visit group_group_members_path(group)
      add_group(group_to_add.name, role)

      expect(page).not_to have_button 'Continue'

      page.refresh

      click_groups_tab

      page.within(first_row) do
        expect(page).to have_content(group_to_add.name)
        expect(page).to have_content(role)
      end
    end
  end

  shared_examples "triggers an overage modal when adding a group with a given role" do |role|
    specify do
      add_group_with_one_extra_user(role)
      click_button 'Continue'

      wait_for_requests
      page.refresh

      click_groups_tab

      page.within(first_row) do
        expect(page).to have_content(group_to_add.name)
        expect(page).to have_content(role)
      end
    end
  end

  before do
    sign_in(user)
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)
    stub_reconciliation_request(true)
  end

  context 'for a free group' do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: nil)
    end

    it_behaves_like "doesn't trigger an overage modal when adding a group with a given role", 'Reporter'
  end

  context 'for a premium group', :aggregate_failures do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 0)
    end

    it_behaves_like "triggers an overage modal when adding a group with a given role", 'Guest'
    it_behaves_like "triggers an overage modal when adding a group with a given role", 'Developer'

    context 'when overage modal is shown' do
      it 'goes back to the initial modal if not confirmed' do
        add_group_with_one_extra_user
        click_button 'Back'

        expect(page).to have_content("You're inviting a group to the #{group.name} group.")

        click_button 'Cancel'

        expect(page).not_to have_link 'Groups'
      end
    end
  end

  context 'for an ultimate group', :aggregate_failures do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan, seats: 1, seats_in_use: 0)
    end

    it_behaves_like "doesn't trigger an overage modal when adding a group with a given role", 'Guest'
    it_behaves_like "triggers an overage modal when adding a group with a given role", 'Developer'
  end

  describe 'inviting group with restricted email domain' do
    shared_examples 'restricted membership by email domain' do
      context 'shared group has membership restricted by allowed email domains' do
        before do
          create(:allowed_email_domain, group: group.root_ancestor, domain: 'gitlab.com')
        end

        context 'shared with group with a subset of allowed email domains' do
          before do
            create(:allowed_email_domain, group: group_to_add.root_ancestor, domain: 'gitlab.com')
          end

          it_behaves_like 'adds group without validation error'
        end

        context 'shared with group containing domains outside the shared group allowed email domains' do
          before do
            create(:allowed_email_domain, group: group_to_add.root_ancestor, domain: 'example.com')
          end

          it_behaves_like 'inviting group fails with allowed email domain error'
        end

        context 'shared with group does not have membership restricted by allowed domains' do
          it_behaves_like 'inviting group fails with allowed email domain error'
        end
      end

      context 'shared group does not have membership restricted by allowed domains' do
        context 'shared with group has membership restricted by allowed email domains' do
          before do
            create(:allowed_email_domain, group: group_to_add.root_ancestor, domain: 'example.com')
          end

          it_behaves_like 'adds group without validation error'
        end

        context 'shared with group does not have membership restricted by allowed domains' do
          it_behaves_like 'adds group without validation error'
        end
      end
    end

    context 'shared group is the root ancestor' do
      let(:group) { create(:group) }
      let(:group_to_add) { create(:group) }

      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: nil)
      end

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared group is a subgroup' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:group_to_add) { create(:group) }

      before do
        create(:gitlab_subscription, namespace: parent_group, hosted_plan: nil)
        parent_group.add_owner(user)
      end

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared with group is a subgroup' do
      let(:group) { create(:group) }
      let(:group_to_add) { create(:group, parent: create(:group)) }

      before do
        create(:gitlab_subscription, namespace: group, hosted_plan: nil)
      end

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared and shared with group are subgroups' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, parent: parent_group) }
      let(:group_to_add) { create(:group, parent: create(:group)) }

      before do
        create(:gitlab_subscription, namespace: parent_group, hosted_plan: nil)
        parent_group.add_owner(user)
      end

      it_behaves_like 'restricted membership by email domain'
    end
  end

  context 'for a group not eligible for reconciliation', :aggregate_failures do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 0)
      stub_reconciliation_request(false)
    end

    it_behaves_like "doesn't trigger an overage modal when adding a group with a given role", 'Reporter'
  end

  def add_group(name, role, expires_at: nil)
    click_on 'Invite a group'

    click_on 'Select a group'
    wait_for_requests
    click_button name
    choose_options(role, expires_at)

    submit_invites
    wait_for_requests
  end

  def add_group_with_one_extra_user(role = 'Developer')
    group.add_owner(user)
    group_to_add.add_owner(user)
    group_to_add.add_developer(user2)

    visit group_group_members_path(group)
    add_group(group_to_add.name, role)

    expect(page).to have_content("Your subscription includes 1 seat. If you continue, the #{group.name} group will"\
      " have 2 seats in use and will be billed for the overage. Learn more.")
  end
end
