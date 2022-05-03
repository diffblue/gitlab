# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AwaitService, :saas do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:root_group) { create(:group) }
    let_it_be(:project) { create(:project, group: root_group) }
    let_it_be(:sub_group) { create(:group, parent: root_group) }

    let(:member) { nil }
    let(:group) { root_group }

    subject(:execute) do
      described_class.new(
        group,
        user: user,
        current_user: current_user
      ).execute
    end

    shared_examples 'returns an error' do |error_message|
      it do
        expect(execute).to be_error
        expect(execute[:message]).to eq error_message
      end
    end

    shared_examples 'succesfully sets member to be awaiting' do
      before do
        expect(member).to be_active
      end

      it 'sets the member state to awaiting', :aggregate_failures do
        expect(execute).to be_success

        expect(member.reload).to be_awaiting
      end

      it 'tracks an audit event' do
        execute

        audit_event = AuditEvent.find_by(author_id: current_user)
        expect(audit_event.author).to eq(current_user)
        expect(audit_event.entity).to eq(group)
        expect(audit_event.target_id).to eq(user.id)
        expect(audit_event.details[:custom_message]).to eq('Changed the membership state to awaiting')
      end
    end

    context 'when unauthorized' do
      it_behaves_like 'returns an error', 'You do not have permission to set a member awaiting'
    end

    context 'when no group is provided' do
      let(:group) { nil }

      it_behaves_like 'returns an error', 'No group provided'
    end

    context 'when no user is provided' do
      let(:user) { nil }

      it_behaves_like 'returns an error', 'No user provided'
    end

    context 'when authorized' do
      before do
        group.add_owner(current_user)
      end

      context 'when member of the root group' do
        it_behaves_like 'succesfully sets member to be awaiting' do
          let(:member) { create(:group_member, :active, group: root_group, user: user) }
        end
      end

      context 'when member of a sub-group' do
        it_behaves_like 'succesfully sets member to be awaiting' do
          let(:member) { create(:group_member, :active, group: sub_group, user: user) }
        end
      end

      context 'when member is an awaiting member of a project' do
        it_behaves_like 'succesfully sets member to be awaiting' do
          let(:member) { create(:project_member, :active, project: project, user: user) }
        end
      end

      context 'when there are multiple member records in the hierarchy' do
        let_it_be(:root_member) { create(:group_member, :active, :developer, group: root_group, user: user) }
        let_it_be(:sub_member) { create(:group_member, :active, :maintainer, group: sub_group, user: user) }
        let_it_be(:project_member) { create(:project_member, :active, :maintainer, project: project, user: user) }

        it 'sets them all to awaiting', :aggregate_failures do
          expect(execute).to be_success

          expect(root_member.reload).to be_awaiting
          expect(sub_member.reload).to be_awaiting
          expect(project_member.reload).to be_awaiting
        end
      end

      context 'when there are no active memberships' do
        let_it_be(:root_member) { create(:group_member, :awaiting, :developer, group: root_group, user: user) }

        it_behaves_like 'returns an error', 'No memberships found'
      end

      it 'does not affect other memberships' do
        other_member = create(:group_member, :awaiting, group: root_group, user: create(:user))

        execute

        expect(other_member.reload).to be_awaiting
      end
    end
  end
end
