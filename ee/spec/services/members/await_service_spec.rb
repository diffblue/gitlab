# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AwaitService, :saas, feature_category: :subgroups do
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

      it 'sets the member state to awaiting and sets updated_at', :aggregate_failures, :freeze_time do
        expect(execute).to be_success

        expect(member.reload).to be_awaiting
        expect(member.updated_at).to eq(Time.current)
      end

      it 'calls UserProjectAccessChangedService' do
        expect_next_instance_of(UserProjectAccessChangedService, user.id) do |service|
          expect(service).to receive(:execute)
        end

        execute
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

      context 'when not the last owner' do
        let_it_be(:owner) { create(:group_member, :owner, group: root_group) }

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

        context 'when current_user is the same user' do
          let_it_be(:current_user) { user }

          before do
            group.add_owner(user)
          end

          it_behaves_like 'returns an error', 'You cannot set yourself to awaiting'
        end

        context 'when user is not member of the group' do
          let_it_be(:member) { create(:group_member, :active, group: create(:group), user: user) }

          it 'returns an error' do
            result = execute

            expect(result[:status]).to eq :error
            expect(result[:message]).to eq 'No memberships found'
          end
        end

        # There is a bug where member records are not valid when the membership to the sub-group
        # has a lower access level than the membership to the parent group.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/362091
        context 'when user has multiple memberships with invalid access levels' do
          let_it_be(:sub_membership) { create(:group_member, :active, :developer, group: sub_group, user: user) }
          let_it_be(:parent_membership) { create(:group_member, :active, :maintainer, group: root_group, user: user) }

          it 'sets all memberships to be awaiting' do
            execute

            expect(sub_membership.reload).to be_awaiting
            expect(parent_membership.reload).to be_awaiting
          end
        end
      end

      context 'when user is the last owner' do
        let_it_be(:user) { current_user }

        it_behaves_like 'returns an error', 'The last owner cannot be set to awaiting'
      end
    end
  end
end
