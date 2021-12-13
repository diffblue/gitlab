# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ActivateService do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group) }
    let_it_be(:project) { create(:project, group: root_group) }
    let_it_be(:sub_group) { create(:group, parent: root_group) }

    let(:member) { nil }
    let(:group) { root_group }
    let(:activate_all) { false }

    subject(:execute) { described_class.new(group, member: member, current_user: current_user, activate_all: activate_all).execute }

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

      it 'activates the member' do
        expect(execute[:status]).to eq :success
        expect(member.reload.active?).to be true
      end

      it 'logs the approval in application logs' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          message: "Group member access approved",
          group: group.id,
          member: member.id,
          approved_by: current_user.id
        )

        execute
      end
    end

    context 'when authorized' do
      before do
        group.add_owner(current_user)
      end

      context 'when activating an individual member' do
        context 'when no member is provided' do
          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No member provided'
          end
        end

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
      end

      context 'when activating all awaiting members' do
        let!(:group_members)   { create_list(:group_member, 5, :awaiting, group: group) }
        let!(:sub_group_members) { create_list(:group_member, 5, :awaiting, group: sub_group) }
        let!(:project_members) { create_list(:project_member, 5, :awaiting, project: project) }

        let(:member) { nil }
        let(:activate_all) { true }

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
            message: "Approved all pending group members",
            group: group.id,
            approved_by: current_user.id
          )

          execute
        end
      end
    end
  end
end
