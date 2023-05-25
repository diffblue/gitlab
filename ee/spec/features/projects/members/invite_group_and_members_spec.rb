# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Members > Invite group and members', feature_category: :groups_and_projects do
  include ActionView::Helpers::DateHelper
  include Features::MembersHelpers

  let(:maintainer) { create(:user) }

  it 'displays the invite modal button triggers' do
    project = create(:project, namespace: create(:group))

    project.add_maintainer(maintainer)
    sign_in(maintainer)

    visit project_project_members_path(project)

    expect(page).to have_selector('.js-invite-members-trigger')
    expect(page).to have_selector('.js-invite-group-trigger')
    expect(page).to have_selector('.js-import-project-members-trigger')
  end

  describe 'Share group lock' do
    shared_examples 'the project cannot be shared with groups' do
      it 'user is only able to share with members' do
        visit project_project_members_path(project)

        expect(page).not_to have_selector('.js-invite-group-trigger')
        expect(page).to have_selector('.js-invite-members-trigger')
      end
    end

    shared_examples 'the project cannot be shared with members' do
      it 'user is only able to share with groups' do
        visit project_project_members_path(project)

        expect(page).not_to have_selector('.js-invite-members-trigger')
        expect(page).to have_selector('.js-invite-group-trigger')
      end
    end

    shared_examples 'the project cannot be shared with groups and members' do
      it 'no invite member or invite group exists' do
        visit project_project_members_path(project)

        expect(page).not_to have_selector('.js-invite-members-trigger')
        expect(page).not_to have_selector('.js-invite-group-trigger')
      end
    end

    shared_examples 'the project can be shared with groups and members' do
      it 'both member and group buttons exist' do
        visit project_project_members_path(project)

        expect(page).to have_selector('.js-invite-members-trigger')
        expect(page).to have_selector('.js-invite-group-trigger')
      end
    end

    context 'for a project in a root group' do
      let!(:group_to_share_with) { create(:group) }
      let(:project) { create(:project, namespace: create(:group)) }

      before do
        project.add_maintainer(maintainer)
        group_to_share_with.add_developer(maintainer)
        sign_in(maintainer)
      end

      context 'when the group has "Share with group lock" and "Member lock" disabled' do
        it_behaves_like 'the project can be shared with groups and members'
      end

      context 'when the group has "Share with group lock" enabled' do
        before do
          project.namespace.update!(share_with_group_lock: true)
        end

        it_behaves_like 'the project cannot be shared with groups'
      end

      context 'when the group has membership lock enabled' do
        before do
          project.namespace.update!(membership_lock: true)
        end

        it_behaves_like 'the project cannot be shared with members'
      end

      context 'when the group has membership lock and "Share with group lock" enabled' do
        before do
          project.namespace.update!(share_with_group_lock: true, membership_lock: true)
        end

        it_behaves_like 'the project cannot be shared with groups and members'
      end
    end

    context 'for a project in a subgroup' do
      let(:root_group) { create(:group) }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, namespace: subgroup) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when the root_group has "Share with group lock" and membership lock disabled' do
        context 'when the subgroup has "Share with group lock" and membership lock disabled' do
          it_behaves_like 'the project can be shared with groups and members'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update!(share_with_group_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end

        context 'when the subgroup has membership lock enabled' do
          before do
            subgroup.update!(membership_lock: true)
          end

          it_behaves_like 'the project cannot be shared with members'
        end

        context 'when the group has membership lock and "Share with group lock" enabled' do
          before do
            subgroup.update!(share_with_group_lock: true, membership_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end
      end

      context 'when the root_group has "Share with group lock" and membership lock enabled' do
        before do
          root_group.update!(share_with_group_lock: true, membership_lock: true)
          subgroup.reload
        end

        # This behaviour should be changed to disable sharing with members as well
        # See: https://gitlab.com/gitlab-org/gitlab-foss/issues/42093
        it_behaves_like 'the project cannot be shared with groups'

        context 'when the subgroup has "Share with group lock" and membership lock disabled (parent overridden)' do
          before do
            subgroup.update!(share_with_group_lock: false, membership_lock: false)
          end

          it_behaves_like 'the project can be shared with groups and members'
        end

        # This behaviour should be changed to disable sharing with members as well
        # See: https://gitlab.com/gitlab-org/gitlab-foss/issues/42093
        context 'when the subgroup has membership lock enabled (parent overridden)' do
          before do
            subgroup.update!(membership_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end

        context 'when the subgroup has "Share with group lock" enabled (parent overridden)' do
          before do
            subgroup.update!(share_with_group_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" and membership lock enabled' do
          before do
            subgroup.update!(membership_lock: true, share_with_group_lock: true)
          end

          it_behaves_like 'the project cannot be shared with groups and members'
        end
      end
    end
  end

  context 'when over free user limit', :saas do
    subject(:visit_page) { visit project_project_members_path(project) }

    context 'with group namespace' do
      let(:role) { :owner }
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group_with_plan, :private, plan: :free_plan) }
      let_it_be(:project) { create(:project, :private, group: group) }

      before do
        group.add_member(user, role)
        sign_in(user)
      end

      it_behaves_like 'over the free user limit alert'
    end
  end
end
