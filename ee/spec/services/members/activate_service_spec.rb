# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ActivateService do
  shared_examples 'handles free user cap' do
    context 'check if free user cap has been reached', :saas do
      let_it_be_with_reload(:root_group) { create(:group_with_plan, plan: :free_plan) }
      let_it_be_with_reload(:sub_group) { create(:group, parent: root_group) }
      let_it_be_with_reload(:project) { create(:project, namespace: root_group) }

      before do
        allow(group).to receive(:user_cap_available?).and_return(false)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when the :free_user_cap feature flag is disabled' do
        before do
          stub_feature_flags(free_user_cap: false)
        end

        it_behaves_like 'successful member activation' do
          let(:member) { create(:group_member, :awaiting, group: group, user: user) }
        end
      end

      context 'when the :free_user_cap feature flag is enabled' do
        before do
          stub_feature_flags(free_user_cap: true)
        end

        context 'when the free user cap has not been reached' do
          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          end

          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }
          end

          it_behaves_like 'successful member activation' do
            let(:member) { create(:project_member, :awaiting, project: project, user: user) }
          end
        end

        context 'when the free user cap has been reached' do
          before do
            stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 1)
          end

          context 'when group member' do
            let(:member) { create(:group_member, :awaiting, group: root_group, user: user) }

            it 'keeps the member awaiting' do
              expect(member).to be_awaiting

              result = execute

              expect(result[:status]).to eq :error
              expect(result[:message]).to eq 'There is no seat left to activate the member'
              expect(member.reload).to be_awaiting
            end
          end

          context 'when sub-group member' do
            let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }

            it 'keeps the member awaiting' do
              expect(member).to be_awaiting

              result = execute

              expect(result[:status]).to eq :error
              expect(result[:message]).to eq 'There is no seat left to activate the member'
              expect(member.reload).to be_awaiting
            end
          end

          context 'when project member' do
            let(:member) { create(:project_member, :awaiting, project: project, user: user) }

            it 'keeps the member awaiting' do
              expect(member).to be_awaiting

              result = execute

              expect(result[:status]).to eq :error
              expect(result[:message]).to eq 'There is no seat left to activate the member'
              expect(member.reload).to be_awaiting
            end
          end

          context 'when there is already an active membership' do
            before do
              stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
            end

            context 'when active group membership' do
              let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }

              before do
                create(:group_member, :active, group: group, user: user)
              end

              it 'sets the group member to active' do
                expect(member).to be_awaiting

                execute

                expect(member.reload).to be_active
              end
            end

            context 'when active project membership' do
              let(:member) { create(:group_member, :awaiting, group: group, user: user) }

              before do
                create(:project_member, :active, project: project, user: user)
              end

              it 'sets the group member to active' do
                expect(member).to be_awaiting

                execute

                expect(member.reload).to be_active
              end
            end
          end
        end
      end
    end
  end

  # There is a bug where member records are not valid when the membership to the sub-group
  # has a lower access level than the membership to the parent group.
  # https://gitlab.com/gitlab-org/gitlab/-/issues/362091
  shared_examples 'when user has multiple memberships with invalid access levels' do
    let_it_be(:member) { create(:group_member, :awaiting, :developer, group: sub_group, user: user) }
    let_it_be(:parent_membership) { create(:group_member, :awaiting, :maintainer, group: root_group, user: user) }

    it 'activates all memberships' do
      execute

      expect(member.reload).to be_active
      expect(parent_membership.reload).to be_active
    end
  end

  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group) }
    let_it_be(:project) { create(:project, group: root_group) }
    let_it_be(:sub_group) { create(:group, parent: root_group) }

    let(:member) { nil }
    let(:group) { root_group }
    let(:params) { { member: member } }

    subject(:execute) { described_class.new(group, current_user: current_user, **params).execute }

    context 'when unauthorized' do
      it 'returns an access error' do
        result = execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'You do not have permission to approve a member'
      end
    end

    context 'when no group is provided' do
      let(:group) { nil }

      it 'returns an error' do
        result = execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq 'No group provided'
      end
    end

    shared_examples 'successful member activation' do
      before do
        expect(member.awaiting?).to be true
      end

      it 'activates the member and sets updated_at', :freeze_time do
        expect(execute[:status]).to eq :success
        expect(member.reload.active?).to be true
        expect(member.updated_at).to eq(Time.current)
      end

      it 'calls UserProjectAccessChangedService' do
        expect_next_instance_of(UserProjectAccessChangedService, [user.id]) do |service|
          expect(service).to receive(:execute).with(blocking: false)
        end

        execute
      end

      it 'logs the approval in application logs' do
        expected_params = {
          message: "Group member access approved",
          group: group.id,
          approved_by: current_user.id
        }

        if params[:member]
          expected_params[:member] = member.id
        elsif params[:user]
          expected_params[:user] = user.id
        end

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

            audit_event = AuditEvent.find_by(author_id: current_user)
            expect(audit_event.author).to eq(current_user)
            expect(audit_event.entity).to eq(group)
            expect(audit_event.target_id).to eq(user.id)
            expect(audit_event.details[:custom_message]).to eq('Changed the membership state to active')
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

    context 'when authorized' do
      before do
        group.add_owner(current_user)
      end

      context 'when member, user or activate_all is not mutual exclusive' do
        let(:params) { { member: member, user: user, activate_all: true } }

        it 'returns an error' do
          result = execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq 'You can only approve an indivdual user, member, or all members'
        end
      end

      context 'when no member, no user or activate_all is provided' do
        let(:params) { {} }

        it 'returns an error' do
          result = execute

          expect(result[:status]).to eq :error
          expect(result[:message]).to eq 'You can only approve an indivdual user, member, or all members'
        end
      end

      context 'when activating an individual member' do
        let(:params) { { member: member } }

        context 'when member is an awaiting member of a root group' do
          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          end
        end

        context 'when member is an awaiting member of a sub-group' do
          let(:group) { sub_group }

          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }
          end
        end

        context 'when member is an awaiting member of a project' do
          it_behaves_like 'successful member activation' do
            let(:member) { create(:project_member, :awaiting, project: project, user: user) }
          end
        end

        context 'when member is not an awaiting member' do
          let(:member) { create(:group_member, group: root_group, user: user) }

          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end

        context 'when there are multiple awaiting member records in the hierarchy' do
          context 'for existing members' do
            let_it_be(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
            let_it_be(:sub_member) { create(:group_member, :awaiting, group: sub_group, user: user) }

            it 'activates the members' do
              expect(execute[:status]).to eq :success
              expect(member.reload.active?).to be true
              expect(sub_member.reload.active?).to be true
            end
          end

          context 'for invited members' do
            let_it_be(:member) { create(:group_member, :awaiting, :invited, group: root_group) }
            let_it_be(:sub_member) { create(:group_member, :awaiting, :invited, group: sub_group, invite_email: member.invite_email) }

            it 'activates the members' do
              expect(execute[:status]).to eq :success
              expect(member.reload.active?).to be true
              expect(sub_member.reload.active?).to be true
            end
          end
        end

        context 'when member is not member of the group' do
          let_it_be(:member) { create(:group_member, :awaiting, group: create(:group), user: user) }

          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end

        it_behaves_like 'handles free user cap'
        it_behaves_like 'when user has multiple memberships with invalid access levels'
      end

      context 'when activating a user' do
        let(:params) { { user: user } }

        context 'when user is an awaiting member of a root group' do
          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          end
        end

        context 'when user is an awaiting member of a sub-group' do
          let(:group) { sub_group }

          it_behaves_like 'successful member activation' do
            let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }
          end
        end

        context 'when user is an awaiting member of a project' do
          it_behaves_like 'successful member activation' do
            let(:member) { create(:project_member, :awaiting, project: project, user: user) }
          end
        end

        context 'when user is not an awaiting member' do
          let(:member) { create(:group_member, group: root_group, user: user) }

          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end

        context 'when there are multiple awaiting member records in the hierarchy for the user' do
          let_it_be(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          let_it_be(:sub_member) { create(:group_member, :awaiting, group: sub_group, user: user) }

          it 'activates the members' do
            expect(execute[:status]).to eq :success
            expect(member.reload.active?).to be true
            expect(sub_member.reload.active?).to be true
          end
        end

        context 'when user is not member of the group' do
          let_it_be(:member) { create(:group_member, :awaiting, group: create(:group), user: user) }

          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end

        it_behaves_like 'handles free user cap'
        it_behaves_like 'when user has multiple memberships with invalid access levels'
      end

      context 'when activating all awaiting members' do
        let!(:group_members)   { create_list(:group_member, 5, :awaiting, group: group) }
        let!(:sub_group_members) { create_list(:group_member, 5, :awaiting, group: sub_group) }
        let!(:project_members) { create_list(:project_member, 5, :awaiting, project: project) }

        let(:member) { nil }
        let(:params) { { activate_all: true } }

        it 'activates all awaiting group members' do
          execute

          group_members.each do |member|
            expect(member.reload.active?).to be true
          end
        end

        it 'activates all awaiting sub_group members' do
          execute

          sub_group_members.each do |member|
            expect(member.reload.active?).to be true
          end
        end

        it 'activates all awaiting project members' do
          execute

          project_members.each do |member|
            expect(member.reload.active?).to be true
          end
        end

        it 'logs the approval in application logs' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            {
              message: "Approved all pending group members",
              group: group.id,
              approved_by: current_user.id
            }
          )

          execute
        end

        it 'calls UserProjectAccessChangedService' do
          double = instance_double(UserProjectAccessChangedService, :execute)
          user_ids = [group_members, sub_group_members, project_members].flatten.map { |m| m.user_id }

          expect(UserProjectAccessChangedService).to receive(:new).with(match_array(user_ids)).and_return(double)
          expect(double).to receive(:execute).with(blocking: false)

          execute
        end

        context 'when on saas', :saas do
          context 'when group is a group with paid plan' do
            let_it_be_with_reload(:root_group) { create(:group_with_plan, plan: :premium_plan) }

            it 'is successful' do
              result = execute

              expect(result[:status]).to eq :success
            end
          end

          context 'when group is a group with a free plan' do
            let_it_be_with_reload(:root_group) { create(:group_with_plan, plan: :free_plan) }

            it 'returns an error' do
              result = execute

              expect(result[:status]).to eq :error
              expect(result[:message]).to eq 'You cannot approve all pending members on a free plan'
            end
          end
        end
      end
    end
  end
end
