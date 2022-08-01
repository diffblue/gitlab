# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Member, type: :model do
  let_it_be(:user) { build :user }
  let_it_be(:group) { create :group }
  let_it_be(:member) { build :group_member, group: group, user: user }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:sub_group_member) { build(:group_member, group: sub_group, user: user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:project_member) { build(:project_member, project: project, user: user) }

  describe '#notification_service' do
    it 'returns a NullNotificationService instance for LDAP users' do
      member = described_class.new

      allow(member).to receive(:ldap).and_return(true)

      expect(member.__send__(:notification_service))
        .to be_instance_of(::EE::NullNotificationService)
    end
  end

  describe '#is_using_seat', :aggregate_failures do
    context 'when hosted on GL.com', :saas do
      it 'calls users check for using the gitlab_com seat method' do
        expect(user).to receive(:using_gitlab_com_seat?).with(group).once.and_return true
        expect(user).not_to receive(:using_license_seat?)
        expect(member.is_using_seat).to be_truthy
      end
    end

    context 'when not hosted on GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return false
      end

      it 'calls users check for using the License seat method' do
        expect(user).to receive(:using_license_seat?).with(no_args).and_return true
        expect(user).not_to receive(:using_gitlab_com_seat?)
        expect(member.is_using_seat).to be_truthy
      end
    end
  end

  describe '#source_kind' do
    subject { member.source_kind }

    context 'when source is of Group kind' do
      it { is_expected.to eq('Group') }
    end

    context 'when source is of Sub group kind' do
      let(:member) { sub_group_member }

      it { is_expected.to eq('Sub group') }
    end

    context 'when source is of Project kind' do
      let(:member) { project_member }

      it { is_expected.to eq('Project') }
    end
  end

  describe '#group_saml_identity' do
    shared_examples_for 'member with group saml identity' do
      context 'without saml_provider' do
        it { is_expected.to eq nil }
      end

      context 'with saml_provider enabled' do
        let!(:saml_provider) { create(:saml_provider, group: member.group) }

        context 'when member has no connected identity' do
          it { is_expected.to eq nil }
        end

        context 'when member has connected identity' do
          let!(:group_related_identity) do
            create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
          end

          it 'returns related identity' do
            expect(group_saml_identity).to eq group_related_identity
          end
        end

        context 'when member has connected identity of different group' do
          before do
            create(:group_saml_identity, user: member.user)
          end

          it { is_expected.to eq nil }
        end
      end
    end

    shared_examples_for 'member with group saml identity on the top level' do
      let!(:saml_provider) { create(:saml_provider, group: parent_group) }

      let!(:group_related_identity) do
        create(:group_saml_identity, user: member.user, saml_provider: saml_provider)
      end

      it 'returns related identity' do
        expect(member.group_saml_identity(root_ancestor: true)).to eq group_related_identity
      end
    end

    describe 'for group members' do
      context 'when member is in a top-level group' do
        let(:member) { create :group_member }

        subject(:group_saml_identity) { member.group_saml_identity }

        it_behaves_like 'member with group saml identity'
      end

      context 'when member is in a subgroup' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }
        let(:member) { create(:group_member, source: group) }

        it_behaves_like 'member with group saml identity on the top level'
      end
    end

    describe 'for project members' do
      context 'when project is nested in a group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, namespace: group) }
        let(:member) { create :project_member, source: project }

        subject(:group_saml_identity) { member.group_saml_identity }

        it_behaves_like 'member with group saml identity'
      end

      context 'when project is nested in a subgroup' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }
        let(:project) { create(:project, namespace: group) }
        let(:member) { create :project_member, source: project }

        it_behaves_like 'member with group saml identity on the top level'
      end

      context 'when project is nested in a personal namespace' do
        let(:project) { create(:project, namespace: create(:user).namespace ) }
        let(:member) { create :project_member, source: project }

        it 'returns nothing' do
          expect(member.group_saml_identity(root_ancestor: true)).to be_nil
        end
      end
    end
  end

  context 'check if user cap has been reached', :saas do
    let_it_be(:group, refind: true) do
      create(:group_with_plan, plan: :ultimate_plan,
             namespace_settings: create(:namespace_settings, new_user_signups_cap: 1))
    end

    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project, refind: true) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_developer(create(:user))
    end

    context 'when the :saas_user_caps feature flag is disabled' do
      before do
        stub_feature_flags(saas_user_caps: false)
      end

      it 'sets the group member state to active' do
        group.add_developer(user)

        expect(user.group_members.last).to be_active
      end

      it 'sets the project member state to active' do
        project.add_developer(user)

        expect(user.project_members.last).to be_active
      end
    end

    context 'when the :saas_user_caps feature flag is enabled for the root group' do
      before do
        stub_feature_flags(saas_user_caps: group)
      end

      context 'when the user cap has not been reached' do
        before do
          group.namespace_settings.update!(new_user_signups_cap: 10)
        end

        it 'sets the group member to active' do
          group.add_developer(user)

          expect(user.group_members.last).to be_active
        end

        it 'sets the project member to active' do
          project.add_developer(user)

          expect(user.project_members.last).to be_active
        end
      end

      context 'when the user cap has been reached' do
        it 'sets the group member to awaiting' do
          group.add_developer(user)

          expect(user.group_members.last).to be_awaiting
        end

        it 'sets the group member to awaiting when added to a subgroup' do
          subgroup.add_developer(user)

          expect(user.group_members.last).to be_awaiting
        end

        it 'sets the project member to awaiting' do
          project.add_developer(user)

          expect(user.project_members.last).to be_awaiting
        end

        context 'when the user is already an active root group member' do
          it 'sets the group member to active' do
            create(:group_member, :active, group: group, user: user)

            subgroup.add_owner(user)

            expect(user.group_members.last).to be_active
          end
        end

        context 'when the user is already an active subgroup member' do
          it 'sets the group member to active' do
            other_subgroup = create(:group, parent: group)
            create(:group_member, :active, group: other_subgroup, user: user)

            subgroup.add_developer(user)

            expect(user.group_members.last).to be_active
          end
        end

        context 'when the user is already an active project member' do
          it 'sets the group member to active' do
            create(:project_member, :active, project: project, user: user)

            expect { subgroup.add_owner(user) }.to change { ::Member.with_state(:active).count }.by(1)
            expect(user.group_members.last).to be_active
          end
        end
      end
    end

    context 'when user is added to a group-less project' do
      let(:project) { create(:project) }

      it 'adds project member and leaves the state to active' do
        project.add_developer(user)

        expect(user.project_members.last).to be_active
      end
    end
  end

  context 'check if free user cap has been reached', :saas do
    let_it_be(:group, refind: true) { create(:group_with_plan, plan: :free_plan) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project, refind: true) { create(:project, namespace: group) }
    let_it_be(:user) { create(:user) }

    before_all do
      group.add_developer(create(:user))
    end

    before do
      allow(group).to receive(:user_cap_available?).and_return(false)
      stub_ee_application_setting(should_check_namespace_plan: true)
    end

    context 'when the :free_user_cap feature flag is disabled' do
      before do
        stub_feature_flags(free_user_cap: false)
      end

      it 'sets the group member state to active' do
        group.add_developer(user)

        expect(user.group_members.last).to be_active
      end

      it 'sets the project member state to active' do
        project.add_developer(user)

        expect(user.project_members.last).to be_active
      end
    end

    context 'when the :free_user_cap feature flag is enabled' do
      before do
        stub_feature_flags(free_user_cap: true)
      end

      context 'when the free user cap has not been reached' do
        it 'sets the group member to active' do
          group.add_developer(user)

          expect(user.group_members.last).to be_active
        end

        it 'sets the project member to active' do
          project.add_developer(user)

          expect(user.project_members.last).to be_active
        end

        context 'when user is added to a group-less project' do
          let(:project) do
            namespace = create(:namespace, :with_namespace_settings)
            project = create(:project, namespace: namespace)
            create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
            project
          end

          it 'adds project member and leaves the state to active' do
            project.root_ancestor.clear_memoization(:existing_free_plan)
            project.add_developer(create(:user))
            project.add_developer(user)

            expect(user.project_members.last).to be_active
          end
        end
      end

      context 'when the free user cap has been reached' do
        before do
          stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)
        end

        it 'sets the group member to awaiting' do
          group.add_developer(user)

          expect(user.group_members.last).to be_awaiting
        end

        it 'sets the group member to awaiting when added to a subgroup' do
          subgroup.add_developer(user)

          expect(user.group_members.last).to be_awaiting
        end

        it 'sets the project member to awaiting' do
          project.add_developer(user)

          expect(user.project_members.last).to be_awaiting
        end

        context 'when multiple members are added' do
          before do
            stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
          end

          it 'sets members to the correct status' do
            over_limit_user = create(:user)
            project.root_namespace.clear_memoization(:billed_user_ids_including_guests)
            project.add_developer(user)
            project.root_namespace.clear_memoization(:billed_user_ids_including_guests)
            project.add_developer(over_limit_user)

            expect(user.project_members.last).to be_active
            expect(over_limit_user.project_members.last).to be_awaiting
          end
        end

        context 'when the user is already an active root group member' do
          it 'sets the group member to active' do
            create(:group_member, :active, group: group, user: user)

            subgroup.add_owner(user)

            expect(user.group_members.last).to be_active
          end
        end

        context 'when the user is already an active subgroup member' do
          it 'sets the group member to active' do
            other_subgroup = create(:group, parent: group)
            create(:group_member, :active, group: other_subgroup, user: user)

            subgroup.add_developer(user)

            expect(user.group_members.last).to be_active
          end
        end

        context 'when the user is already an active project member' do
          it 'sets the group member to active' do
            create(:project_member, :active, project: project, user: user)

            expect { subgroup.add_owner(user) }.to change { ::Member.with_state(:active).count }.by(1)
            expect(user.group_members.last).to be_active
          end
        end

        context 'when user is added to a group-less project' do
          let(:project) do
            namespace = create(:namespace, :with_namespace_settings)
            project = create(:project, namespace: namespace)
            create(:gitlab_subscription, hosted_plan: create(:free_plan), namespace: namespace)
            project
          end

          before do
            stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
          end

          it 'adds multiple members and correctly shows the state' do
            project.root_ancestor.clear_memoization(:has_free_or_no_subscription)
            over_limit_user = create(:user)

            project.root_ancestor.clear_memoization(:free_plan_user_ids)
            project.add_developer(user)
            project.root_ancestor.clear_memoization(:free_plan_user_ids)
            project.add_developer(over_limit_user)

            expect(user.project_members.last).to be_active
            expect(over_limit_user.project_members.last).to be_awaiting
          end
        end
      end
    end
  end

  context 'when activating a member', :saas do
    let(:user_cap) { true }
    let(:member) { group.members.last }

    let_it_be(:group, refind: true) { create(:group_with_plan, plan: :free_plan) }
    let_it_be(:project, refind: true) { create(:project, namespace: group) }
    let_it_be(:active_user) { create(:user) }
    let_it_be(:active_member) { create(:group_member, :maintainer, group: group, user: active_user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:member, refind: true) { create(:group_member, :awaiting, :maintainer, group: group, user: user) }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)

      allow_next_found_instance_of(Group) do |group|
        allow(group).to receive(:apply_user_cap?).and_return(apply_user_cap)
      end

      expect(member).to be_awaiting
    end

    context 'when limit has been reached and user cap does not apply' do
      let(:apply_user_cap) { false }

      it 'activates user' do
        member.activate

        expect(member).to be_active
      end
    end

    context 'when user cap applies' do
      let(:apply_user_cap) { true }

      context 'when limit has been reached' do
        it 'keeps user awaiting' do
          member.activate

          expect(member).to be_awaiting
        end

        context 'when user already has an other active membership' do
          context 'when project membership' do
            let(:member) { create(:project_member, :awaiting, :maintainer, project: project, user: active_user) }

            it 'activates member for the same user' do
              member.activate

              expect(member).to be_active
            end
          end

          context 'when sub-group membership' do
            let(:member) { create(:group_member, :awaiting, :maintainer, group: sub_group, user: active_user) }

            it 'activates member for the same user' do
              member.activate

              expect(member).to be_active
            end
          end
        end

        context 'when user has an other awaiting membership' do
          let(:member) { create(:project_member, :awaiting, :maintainer, project: project, user: user) }

          it 'keeps the member awaiting' do
            member.activate

            expect(member).to be_awaiting
          end
        end
      end

      context 'when there is enough capacity' do
        before do
          stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
        end

        it 'activates member' do
          member.activate

          expect(member).to be_active
        end
      end
    end
  end

  context 'when setting the member to awaiting', :saas do
    let_it_be(:group, refind: true) { create(:group_with_plan, plan: :free_plan) }
    let_it_be(:member) { create(:group_member, :active, :owner, group: group) }

    context 'when user is the last owner' do
      it 'does not allow the member to be awaiting' do
        expect(member).to be_active

        member.wait

        expect(member).to be_active
      end
    end

    context 'when user is not the last owner' do
      let_it_be(:second_owner) { create(:group_member, :owner, group: group) }

      it 'sets the member to awaiting' do
        expect(member).to be_active

        member.wait

        expect(member).to be_awaiting
      end
    end

    context 'when invite' do
      let_it_be(:member) { create(:group_member, :invited, :active, group: group) }

      it 'sets the member to awaiting' do
        expect(member).to be_active

        member.wait

        expect(member).to be_awaiting
      end
    end
  end

  describe '.distinct_awaiting_or_invited_for_group' do
    let_it_be(:other_sub_group) { create(:group, parent: group) }
    let_it_be(:active_group_member) { create(:group_member, group: group) }
    let_it_be(:awaiting_group_member) { create(:group_member, :awaiting, group: group) }
    let_it_be(:awaiting_subgroup_member) { create(:group_member, :awaiting, group: sub_group) }
    let_it_be(:awaiting_other_subgroup_member) { create(:group_member, :awaiting, user: awaiting_subgroup_member.user, group: other_sub_group) }
    let_it_be(:awaiting_project_member) { create(:project_member, :awaiting, project: project) }
    let_it_be(:awaiting_invited_member) { create(:group_member, :awaiting, :invited, group: group) }
    let_it_be(:active_invited_member) { create(:group_member, :invited, group: group) }
    let_it_be(:awaiting_previously_invited_member) do
      member = create(:group_member, :awaiting, :invited, group: group)
      user = create(:user)
      member.accept_invite!(user)

      member
    end

    subject(:results) { described_class.distinct_awaiting_or_invited_for_group(group) }

    it 'returns the correct members' do
      expect(results).to contain_exactly(
        awaiting_group_member,
        awaiting_subgroup_member,
        awaiting_project_member,
        awaiting_invited_member,
        awaiting_previously_invited_member,
        active_invited_member
      )
    end

    it 'does not return additional results for duplicates' do
      create(:group_member, :awaiting, group: sub_group, user: awaiting_group_member.user)
      create(:group_member, :invited, group: sub_group, invite_email: awaiting_invited_member.invite_email)
      create(:group_member, :awaiting, group: sub_group, invite_email: awaiting_previously_invited_member.invite_email, user: awaiting_previously_invited_member.user)

      expect(results.map(&:user_id).compact).to contain_exactly(
        awaiting_group_member.user_id,
        awaiting_subgroup_member.user_id,
        awaiting_project_member.user_id,
        awaiting_previously_invited_member.user_id
      )

      expect(results.map(&:invite_email).compact).to contain_exactly(
        awaiting_invited_member.invite_email,
        active_invited_member.invite_email,
        awaiting_previously_invited_member.invite_email
      )
    end
  end

  describe '.awaiting_without_invites_and_requests' do
    let_it_be(:awaiting_group_member) { create(:group_member, :awaiting, group: group) }
    let_it_be(:awaiting_project_member) { create(:project_member, :awaiting, project: project) }
    let_it_be(:active_group_member) { create(:group_member, group: group) }
    let_it_be(:invited_member) { create(:group_member, :invited, group: group) }
    let_it_be(:invited_awaiting_member) { create(:group_member, :invited, :awaiting, group: group) }
    let_it_be(:accepted_invite_member) { create(:group_member, :invited, group: group).accept_request }
    let_it_be(:requested_member) { create(:group_member, :access_request, group: group) }
    let_it_be(:requested_awaiting_member) { create(:group_member, :awaiting, :access_request, group: group) }
    let_it_be(:accepted_request_member) { create(:group_member, :access_request, group: group).accept_request }
    let_it_be(:blocked_member) { create(:group_member, :blocked, group: group) }

    subject(:results) { described_class.awaiting_without_invites_and_requests }

    it { is_expected.to include awaiting_group_member }
    it { is_expected.to include awaiting_project_member }

    it { is_expected.not_to include active_group_member }
    it { is_expected.not_to include invited_member }
    it { is_expected.not_to include invited_awaiting_member }
    it { is_expected.not_to include accepted_invite_member }
    it { is_expected.not_to include requested_member }
    it { is_expected.not_to include requested_awaiting_member }
    it { is_expected.not_to include accepted_request_member }
    it { is_expected.not_to include blocked_member }
  end
end
