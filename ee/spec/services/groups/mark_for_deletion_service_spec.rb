# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MarkForDeletionService, feature_category: :subgroups do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  subject { described_class.new(group, user, {}).execute }

  before do
    stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
  end

  context 'marking the group for deletion' do
    context 'with user that can admin the group' do
      before do
        group.add_owner(user)
      end

      context 'for a group that has not been marked for deletion' do
        it 'marks the group for deletion' do
          subject

          expect(group.marked_for_deletion_on).to eq(Date.today)
          expect(group.deleting_user).to eq(user)
        end

        it 'returns success' do
          expect(subject).to eq({ status: :success })
        end

        context 'marking for deletion fails' do
          before do
            expect_next_instance_of(GroupDeletionSchedule) do |group_deletion_schedule|
              allow(group_deletion_schedule).to receive_message_chain(:errors, :full_messages)
                .and_return(['error message'])

              allow(group_deletion_schedule).to receive(:save).and_return(false)
            end
          end

          it 'returns error' do
            expect(subject).to eq({ status: :error, message: 'error message' })
          end
        end
      end

      context 'for a group that has been marked for deletion' do
        let(:deletion_date) { 3.days.ago }
        let(:group) do
          create(:group_with_deletion_schedule,
                 marked_for_deletion_on: deletion_date,
                 deleting_user: user)
        end

        it 'does not change the attributes associated with delayed deletion' do
          subject

          expect(group.marked_for_deletion_on).to eq(deletion_date.to_date)
          expect(group.deleting_user).to eq(user)
        end

        it 'returns error' do
          expect(subject).to eq({ status: :error, message: 'Group has been already marked for deletion' })
        end
      end

      context 'audit events' do
        it 'logs audit event' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(name: 'group_deletion_marked')
          ).and_call_original

          expect { subject }.to change { AuditEvent.count }.by(1)
        end
      end
    end

    context 'with a user that cannot admin the group' do
      it 'does not mark the group for deletion' do
        subject

        expect(group.marked_for_deletion?).to be_falsey
      end

      it 'returns error' do
        expect(subject).to eq({ status: :error, message: 'You are not authorized to perform this action' })
      end

      context 'audit events' do
        it 'does not log audit event' do
          expect { subject }.not_to change { AuditEvent.count }
        end
      end
    end
  end
end
