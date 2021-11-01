# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ActivateService do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group) }
    let_it_be(:project) { create(:project, group: root_group) }
    let_it_be(:sub_group) { create(:group, parent: root_group) }

    let(:group) { root_group }
    let(:activate_all) { false }

    subject(:execute) { described_class.new(group, user: user, current_user: current_user, activate_all: activate_all).execute }

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

    shared_examples 'successful user activation' do
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
          user: user.id,
          approved_by: current_user.id
        )

        execute
      end
    end

    context 'when authorized' do
      before do
        group.add_owner(current_user)
      end

      context 'when activating an individual user' do
        context 'when user is an awaiting member of a root group' do
          it_behaves_like 'successful user activation' do
            let(:member) { create(:group_member, :awaiting, group: root_group, user: user) }
          end
        end

        context 'when user is an awaiting member of a sub-group' do
          let(:group) { sub_group }

          it_behaves_like 'successful user activation' do
            let(:member) { create(:group_member, :awaiting, group: sub_group, user: user) }
          end
        end

        context 'when user is an awaiting member of a project' do
          it_behaves_like 'successful user activation' do
            let(:member) { create(:project_member, :awaiting, project: project, user: user) }
          end
        end

        context 'when user is not an awaiting member' do
          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end
      end

      context 'when activating all awaiting members' do
        let!(:group_members)   { create_list(:group_member, 5, :awaiting, group: group) }
        let!(:sub_group_members) { create_list(:group_member, 5, :awaiting, group: sub_group) }
        let!(:project_members) { create_list(:project_member, 5, :awaiting, project: project) }

        let(:user) { nil }
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
