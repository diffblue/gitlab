# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Manage members' do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:group) { create(:group) }

  before do
    sign_in(user1)
  end

  context 'when adding a member to a group triggers an overage', :js, :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com?) { true }
      create(:gitlab_subscription, namespace: group)
      stub_application_setting(check_namespace_plan: true)
    end

    it 'show an overage modal and invites a member to a group if confirmed' do
      group.add_owner(user1)

      visit group_group_members_path(group)

      click_on 'Invite members'

      page.within '[data-testid="invite-modal"]' do
        find('[data-testid="members-token-select-input"]').set(user2.name)

        wait_for_requests
        click_button user2.name
        choose_options('Developer', nil)

        click_button 'Invite'

        expect(page).to have_content("Your subscription includes 10 seats. If you continue, the #{group.name} group will have 1 seat in use and will be billed for the overage. Learn more.")

        click_button 'Continue'

        page.refresh
      end

      page.within(second_row) do
        expect(page).to have_content(user2.name)
        expect(page).to have_button('Developer')
      end
    end

    it 'show an overage modal and get back to initial modal if not confirmed' do
      group.add_owner(user1)

      visit group_group_members_path(group)

      click_on 'Invite members'

      page.within '[data-testid="invite-modal"]' do
        find('[data-testid="members-token-select-input"]').set(user2.name)

        wait_for_requests
        click_button user2.name
        choose_options('Developer', nil)

        click_button 'Invite'

        expect(page).to have_content("Your subscription includes 10 seats. If you continue, the #{group.name} group will have 1 seat in use and will be billed for the overage. Learn more.")

        click_button 'Back'
      end

      expect(page).to have_content("You're inviting members to the #{group.name} group.")

      click_button 'Cancel'

      expect(page).not_to have_content(user2.name)
      expect(page).not_to have_button('Developer')
    end
  end
end
