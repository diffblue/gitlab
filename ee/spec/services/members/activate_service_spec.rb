# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ActivateService, feature_category: :subgroups do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: root_group) }
  let_it_be(:project) { create(:project, group: root_group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:non_awaiting_membership) { create(:group_member, group: root_group) }

  shared_examples 'successful member activation' do
    it 'activates the member and sets updated_at', :freeze_time do
      expect(execute[:status]).to eq :success

      members.each do |member|
        expect(member.reload).to be_active
        expect(member.updated_at).to eq(Time.current)
      end
    end

    it 'calls UserProjectAccessChangedService' do
      expect_next_instance_of(UserProjectAccessChangedService, match_array(members.map(&:user_id).uniq)) do |service|
        expect(service).to receive(:execute)
      end

      execute
    end

    it 'logs the approval in application logs' do
      expected_params = {
        message: "Group member access approved",
        group: root_group.id,
        approved_by: current_user.id,
        members: match_array(members.map(&:id))
      }

      expect(Gitlab::AppLogger).to receive(:info).with(expected_params)

      execute
    end

    context 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true, audit_events: true, extended_audit_events: true)
        end

        it 'tracks an audit event' do
          execute

          members.each do |member|
            audit_event = AuditEvent.find_by(target_id: member.id)
            expect(audit_event.author).to eq(current_user)
            expect(audit_event.entity).to eq(root_group)
            expect(audit_event.details[:custom_message]).to eq('Changed the membership state to active')
          end
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(admin_audit_log: false, audit_events: false, extended_audit_events: false)
        end

        it 'does not track audit event' do
          expect { execute }.not_to change { AuditEvent.count }
        end
      end
    end
  end

  shared_examples 'returns an error' do |error_message|
    it do
      result = execute

      expect(result[:status]).to eq :error
      expect(result[:message]).to eq error_message
    end
  end

  # There is a bug where member records are not valid when the membership to the sub-group
  # has a lower access level than the membership to the parent group.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/362091
  shared_examples 'when a user has memberships with invalid access levels' do
    let_it_be(:member) { create(:group_member, :awaiting, :developer, group: sub_group, user: user) }
    let_it_be(:parent_membership) { create(:group_member, :awaiting, :maintainer, group: root_group, user: user) }

    it 'activates all memberships' do
      execute

      expect(member.reload).to be_active
      expect(parent_membership.reload).to be_active
    end
  end

  describe '.for_invite' do
    let_it_be(:other_membership) { create(:group_member, :awaiting, :invited, group: root_group, invite_email: 'other@example.com') }
    let_it_be(:invite_email) { 'test@example.com' }
    let_it_be(:expected_members) do
      [
        create(:group_member, :awaiting, :invited, group: root_group, invite_email: invite_email),
        create(:group_member, :awaiting, :invited, group: sub_group, invite_email: invite_email),
        create(:project_member, :awaiting, :invited, project: project, invite_email: invite_email)
      ]
    end

    it 'creates a new instance with the correct members' do
      expect(described_class).to receive(:new).with(root_group, memberships: match_array(expected_members))

      described_class.for_invite(root_group, invite_email: invite_email)
    end
  end

  describe '.for_users' do
    let_it_be(:user2) { create(:user) }
    let_it_be(:user_without_membership) { create(:user) }
    let_it_be(:expected_members) do
      [
        create(:group_member, :awaiting, group: root_group, user: user),
        create(:group_member, :awaiting, group: root_group, user: user2),
        create(:group_member, :awaiting, group: sub_group, user: user),
        create(:group_member, :awaiting, group: sub_group, user: user2),
        create(:project_member, :awaiting, :owner, project: project, user: user),
        create(:project_member, :awaiting, :owner, project: project, user: user2)
      ]
    end

    it 'creates a new instance with the correct members' do
      expect(described_class).to receive(:new).with(root_group, memberships: match_array(expected_members))

      described_class.for_users(root_group, users: [user, user2, user_without_membership])
    end
  end

  describe '.for_group' do
    let_it_be(:expected_members) do
      [
        create(:group_member, :awaiting, group: root_group),
        create(:group_member, :awaiting, group: sub_group),
        create(:project_member, :awaiting, project: project)
      ]
    end

    it 'creates a new instance with the correct members' do
      expect(described_class).to receive(:new).with(root_group, memberships: match_array(expected_members))

      described_class.for_group(root_group)
    end
  end

  describe '#execute' do
    let_it_be(:current_user) { create(:user) }

    subject(:execute) { described_class.for_group(root_group).execute(current_user: current_user) }

    context 'when unauthorized' do
      it_behaves_like 'returns an error', 'You do not have permission to approve a member'
    end

    context 'when current_user is nil' do
      let_it_be(:current_user) { nil }

      it_behaves_like 'returns an error', 'You do not have permission to approve a member'
    end

    context 'when skipping authorization' do
      let_it_be(:current_user) { User.automation_bot }

      let_it_be(:members) { [create(:group_member, :awaiting, group: root_group, user: user)] }

      subject(:execute) { described_class.for_group(root_group).execute(current_user: current_user, skip_authorization: true) }

      it_behaves_like 'successful member activation'
    end

    context 'when authorized' do
      before do
        root_group.add_owner(current_user)
      end

      context 'when there are awaiting members' do
        let_it_be(:members) do
          [
            create(:group_member, :awaiting, group: root_group),
            create(:group_member, :awaiting, group: sub_group),
            create(:project_member, :awaiting, project: project)
          ]
        end

        it_behaves_like 'successful member activation'
      end

      context 'when there are other awaiting members' do
        let_it_be(:other_group) { create(:group) }

        context 'with .for_invite' do
          subject(:execute) { described_class.for_invite(root_group, invite_email: invite_email).execute(current_user: current_user) }

          let_it_be(:invite_email) { 'test@example.com' }
          let_it_be(:member) { create(:group_member, :awaiting, :invited, group: root_group, invite_email: invite_email) }
          let_it_be(:other_awaiting_member) { create(:group_member, :awaiting, :invited, group: other_group, invite_email: invite_email) }

          it 'activates only provided invite' do
            result = execute

            expect(result[:status]).to eq(:success)
            expect(member.reload).to be_active
            expect(other_awaiting_member.reload).to be_awaiting
          end
        end

        context 'with .for_users' do
          subject(:execute) { described_class.for_users(root_group, users: [user]).execute(current_user: current_user) }

          let_it_be(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          let_it_be(:other_awaiting_member) { create(:group_member, :awaiting, group: other_group, user: user) }

          it 'activates only provided invite' do
            result = execute

            expect(result[:status]).to eq(:success)
            expect(member.reload).to be_active
            expect(other_awaiting_member.reload).to be_awaiting
          end
        end

        context 'with .for_group' do
          subject(:execute) { described_class.for_group(root_group).execute(current_user: current_user) }

          let_it_be(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          let_it_be(:other_awaiting_member) { create(:group_member, :awaiting, group: other_group, user: user) }

          it 'activates only provided invite' do
            result = execute

            expect(result[:status]).to eq(:success)
            expect(member.reload).to be_active
            expect(other_awaiting_member.reload).to be_awaiting
          end
        end
      end

      context 'when there are other awaiting members for invite' do
        let_it_be(:invite_email) { 'test@example.com' }
        subject(:execute) { described_class.for_invite(root_group, invite_email: invite_email).execute(current_user: current_user) }

        let_it_be(:member) { create(:group_member, :awaiting, :invited, group: root_group, invite_email: invite_email) }
        let_it_be(:other_awaiting_member) { create(:group_member, :awaiting, group: root_group) }

        it 'activates only provided members' do
          result = execute

          expect(result[:status]).to eq(:success)
          expect(other_awaiting_member.reload).to be_awaiting
        end
      end

      context 'when users are no awaiting members' do
        let_it_be(:members) { [create(:group_member, group: root_group, user: user)] }

        it_behaves_like 'returns an error', 'No memberships found'
      end

      context 'when the members are only invites' do
        let_it_be(:members) { [create(:group_member, :invited, group: root_group)] }

        it 'does not call UserProjectAccessChangedService' do
          expect(UserProjectAccessChangedService).not_to receive(:new)

          execute
        end
      end

      it_behaves_like 'when a user has memberships with invalid access levels'
    end
  end
end
