# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Manage members', :js, feature_category: :subgroups do
  include Spec::Support::Helpers::Features::InviteMembersModalHelper

  context 'with free user limit', :saas do
    before do
      stub_ee_application_setting(dashboard_limit_enabled: true)
    end

    context 'when at free user limit' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_enforcement_limit: 1)
        group = create(:group_with_plan, :private, plan: :free_plan)
        project = create(:project, :private, group: group)
        user = project.creator
        group.add_owner(user)

        sign_in(user)

        visit project_project_members_path(project)

        click_on 'Invite members'

        page.within invite_modal_selector do
          expect(page).to have_content "You've reached your"
          expect(page).to have_content 'To invite new users to this namespace, you must remove existing users.'
        end
      end
    end

    context 'when close to free user limit on new namespace' do
      it 'shows the alert notification in the modal' do
        stub_ee_application_setting(dashboard_limit: 4)
        stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: 2.days.ago)
        group = create(:group_with_plan, :private, plan: :free_plan)
        project = create(:project, :private, group: group)
        user = project.creator
        group.add_owner(user)

        sign_in(user)

        visit project_project_members_path(project)

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
end
