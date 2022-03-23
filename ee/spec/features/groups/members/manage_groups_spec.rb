# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage groups', :js, :saas do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_to_add) { create(:group) }

  let(:premium_plan) { create(:premium_plan) }

  shared_examples "adding a group doesn't trigger an overage modal" do
    it do
      group.add_owner(user)
      group_to_add.add_owner(user)

      visit group_group_members_path(group)
      add_group(group_to_add.name, role: 'Reporter')

      wait_for_requests

      expect(page).not_to have_button 'Continue'

      page.refresh

      click_groups_tab

      page.within(first_row) do
        expect(page).to have_content(group_to_add.name)
        expect(page).to have_content('Reporter')
      end
    end
  end

  before do
    sign_in(user)
    stub_application_setting(check_namespace_plan: true)
  end

  context 'for a free group' do
    before do
      allow(group).to receive(:paid?).and_return(false)
    end

    it_behaves_like "adding a group doesn't trigger an overage modal"
  end

  context 'for a premium group', :aggregate_failures do
    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: premium_plan, seats: 1, seats_in_use: 0)
    end

    context 'when there is an not yet billed user in the additional group' do
      it 'triggers overage modal' do
        add_group_with_one_extra_user
        click_button 'Continue'

        wait_for_requests
        page.refresh

        click_groups_tab

        page.within(first_row) do
          expect(page).to have_content(group_to_add.name)
          expect(page).to have_content('Reporter')
        end
      end
    end

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

  def add_group(name, role: 'Guest', expires_at: nil)
    click_on 'Invite a group'

    click_on 'Select a group'
    wait_for_requests
    click_button name
    choose_options(role, expires_at)

    click_button 'Invite'
  end

  def add_group_with_one_extra_user
    group.add_owner(user)
    group_to_add.add_owner(user)
    group_to_add.add_developer(user2)

    visit group_group_members_path(group)
    add_group(group_to_add.name, role: 'Reporter')

    wait_for_requests

    expect(page).to have_content("Your subscription includes 1 seat. If you continue, the #{group.name} group will have 2 seats in use and will be billed for the overage. Learn more.")
  end
end
