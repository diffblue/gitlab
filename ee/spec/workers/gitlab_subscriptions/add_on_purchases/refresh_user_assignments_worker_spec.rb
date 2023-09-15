# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::RefreshUserAssignmentsWorker, feature_category: :seat_cost_management do
  describe '#perform' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: add_on) }
    let_it_be(:other_add_on_purchase) { create(:gitlab_subscription_add_on_purchase, add_on: add_on) }

    let(:root_namespace_id) { namespace.id }

    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }

    before_all do
      add_on_purchase.assigned_users.create!(user: user_1)
      add_on_purchase.assigned_users.create!(user: user_2)

      other_add_on_purchase.assigned_users.create!(user: create(:user))
    end

    shared_examples 'does not remove seat assignment' do
      specify do
        expect do
          subject.perform(root_namespace_id)
        end.not_to change { GitlabSubscriptions::UserAddOnAssignment.count }
      end
    end

    context 'when root_namespace_id does not exists' do
      let(:root_namespace_id) { nil }

      it_behaves_like 'does not remove seat assignment'
    end

    context 'when root namespace does not have related purchase' do
      let(:root_namespace_id) { create(:group).id }

      it_behaves_like 'does not remove seat assignment'
    end

    describe 'idempotence' do
      include_examples 'an idempotent worker' do
        let(:job_args) { [root_namespace_id] }

        it 'removes the all ineligible user assignments' do
          expect do
            subject
          end.to change { GitlabSubscriptions::UserAddOnAssignment.where(add_on_purchase: add_on_purchase).count }
            .by(-2)

          # other not related user assignments remain intact
          expect(other_add_on_purchase.assigned_users.count).to eq(1)
        end

        context 'when some user is still eligible for assignment' do
          before_all do
            namespace.add_guest(user_1)
          end

          it 'removes only the ineligible user assignment' do
            expect do
              subject
            end.to change { GitlabSubscriptions::UserAddOnAssignment.count }.by(-1)

            expect(add_on_purchase.assigned_users.by_user(user_1).count).to eq(1)
          end
        end
      end
    end

    it 'logs an info about assignments refreshed' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        message: 'AddOnPurchase user assignments refreshed in bulk',
        deleted_assignments_count: 2,
        add_on: add_on_purchase.add_on.name,
        namespace: namespace.path
      )

      subject.perform(root_namespace_id)
    end

    context 'when no assignments were deleted' do
      before_all do
        namespace.add_guest(user_1)
        namespace.add_guest(user_2)
      end

      it 'does not log any info about assignments refreshed' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        subject.perform(root_namespace_id)
      end
    end

    context 'with exclusive lease' do
      include ExclusiveLeaseHelpers

      let(:lock_key) { "#{described_class.name.underscore}:#{root_namespace_id}" }
      let(:timeout) { described_class::LEASE_TTL }

      context 'when exclusive lease has not been taken' do
        it 'obtains a new exclusive lease' do
          expect_to_obtain_exclusive_lease(lock_key, timeout: timeout)

          subject.perform(root_namespace_id)
        end
      end

      context 'when exclusive lease has already been taken' do
        before do
          stub_exclusive_lease_taken(lock_key, timeout: timeout)
        end

        it 'raises an error' do
          expect { subject.perform(root_namespace_id) }
            .to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        end
      end
    end
  end
end
