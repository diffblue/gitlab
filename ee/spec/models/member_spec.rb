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
        let(:project) { create(:project, namespace: group)}
        let(:member) { create :project_member, source: project }

        subject(:group_saml_identity) { member.group_saml_identity }

        it_behaves_like 'member with group saml identity'
      end

      context 'when project is nested in a subgroup' do
        let(:parent_group) { create(:group)}
        let(:group) { create(:group, parent: parent_group) }
        let(:project) { create(:project, namespace: group)}
        let(:member) { create :project_member, source: project }

        it_behaves_like 'member with group saml identity on the top level'
      end

      context 'when project is nested in a personal namespace' do
        let(:project) { create(:project, namespace: create(:user).namespace )}
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

    let_it_be(:project, refind: true) { create(:project, namespace: group)}
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
          subgroup = create(:group, parent: group)

          subgroup.add_developer(user)

          expect(user.group_members.last).to be_awaiting
        end

        it 'sets the project member to awaiting' do
          project.add_developer(user)

          expect(user.project_members.last).to be_awaiting
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
end
