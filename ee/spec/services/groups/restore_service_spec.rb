# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RestoreService, feature_category: :subgroups do
  let(:user) { create(:user) }
  let(:group) do
    create(:group_with_deletion_schedule,
           marked_for_deletion_on: 1.day.ago,
           deleting_user: user)
  end

  subject { described_class.new(group, user, {}).execute }

  before do
    stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
  end

  context 'restoring the group' do
    context 'with a user that can admin the group' do
      before do
        group.add_owner(user)
      end

      context 'for a group that has been marked for deletion' do
        it 'removes the mark for deletion' do
          subject

          expect(group.marked_for_deletion_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns success' do
          result = subject

          expect(result).to eq({ status: :success })
        end

        context 'restoring fails' do
          it 'returns error' do
            allow(group.deletion_schedule).to receive(:destroy).and_return(false)

            result = subject

            expect(result).to eq({ status: :error, message: 'Could not restore the group' })
          end
        end
      end

      context 'for a group that has not been marked for deletion' do
        let(:group) { create(:group) }

        it 'does not change the attributes associated with delayed deletion' do
          subject

          expect(group.marked_for_deletion_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns error' do
          result = subject

          expect(result).to eq({ status: :error, message: 'Group has not been marked for deletion' })
        end
      end

      context 'audit events' do
        it 'logs audit event' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(name: 'group_restored')
          ).and_call_original

          expect { subject }.to change { AuditEvent.count }.by(1)
        end
      end
    end

    context 'with a user that cannot admin the group' do
      it 'does not restore the group' do
        subject

        expect(group.marked_for_deletion?).to be_truthy
      end

      it 'returns error' do
        result = subject

        expect(result).to eq({ status: :error, message: 'You are not authorized to perform this action' })
      end

      context 'audit events' do
        it 'does not log audit event' do
          expect { subject }.not_to change { AuditEvent.count }
        end
      end
    end
  end
end
