# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::RefreshUserAssignmentsWorker, feature_category: :seat_cost_management do
  describe '#perform' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase, namespace: namespace, add_on: add_on) }

    let(:root_namespace_id) { namespace.id }

    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }

    before_all do
      add_on_purchase.assigned_users.create!(user: user_1)
      add_on_purchase.assigned_users.create!(user: user_2)
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
  end
end
