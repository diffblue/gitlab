# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Manage groups', feature_category: :subgroups do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers

  shared_examples 'adds group without validation error' do
    specify do
      group.add_owner(user)
      group_to_add.add_owner(user)
      sign_in(user)

      role = 'Maintainer'
      visit project_project_members_path(project)
      add_group(group_to_add.name, role)

      page.refresh

      click_groups_tab

      page.within(first_row) do
        expect(page).to have_content(group_to_add.name)
        expect(page).to have_content(role)
      end
    end
  end

  shared_examples 'inviting group fails with allowed email domain error' do
    specify do
      group.add_owner(user)
      group_to_add.add_owner(user)
      sign_in(user)

      visit project_project_members_path(project)
      add_group(group_to_add.name, 'Maintainer')

      error_msg = 'Invited group allowed email domains must contain a subset of the allowed email domains'\
      ' of the root ancestor group'
      expect(page).to have_content(error_msg)
    end
  end

  describe 'inviting group with restricted email domain', :js do
    shared_examples 'restricted membership by email domain' do
      let(:user) { create(:user) }
      let(:project) { create(:project, group: group) }

      context 'shared project group has membership restricted by allowed email domains' do
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

      context 'shared project group does not have membership restricted by allowed domains' do
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

    context 'shared project group is the root ancestor' do
      let(:group) { create(:group) }
      let(:group_to_add) { create(:group) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared project group is a subgroup' do
      let(:group) { create(:group, parent: create(:group)) }
      let(:group_to_add) { create(:group) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared with group is a subgroup' do
      let(:group) { create(:group) }
      let(:group_to_add) { create(:group, parent: create(:group)) }

      it_behaves_like 'restricted membership by email domain'
    end

    context 'shared project group and shared with group are subgroups' do
      let(:group) { create(:group, parent: create(:group)) }
      let(:group_to_add) { create(:group, parent: create(:group)) }

      it_behaves_like 'restricted membership by email domain'
    end
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
end
