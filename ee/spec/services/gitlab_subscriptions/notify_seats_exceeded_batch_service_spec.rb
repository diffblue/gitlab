# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::NotifySeatsExceededBatchService,
  :timecop, :saas, feature_category: :billing_and_payments do
  describe '.execute' do
    context 'when subscriptions are present' do
      let(:changed_at_time) { Time.current.beginning_of_day - 1.hour }
      let(:user_namespace_owner) { user_namespace.owner }
      let(:group_namespace_owner) { create(:user) }
      let(:user_namespace) { create(:user_namespace) }

      let(:group_namespace) do
        group = create(:group)
        group.add_owner(group_namespace_owner)

        group
      end

      let!(:user_namespace_subscription) do
        create(:gitlab_subscription, namespace: user_namespace, max_seats_used_changed_at: changed_at_time)
      end

      let!(:group_namespace_subscription) do
        create(:gitlab_subscription, namespace: group_namespace, max_seats_used_changed_at: changed_at_time)
      end

      it 'sends notifications' do
        expect(Gitlab::SubscriptionPortal::Client).to receive(:send_seat_overage_notification_batch).with(
          a_collection_containing_exactly(
            {
              glNamespaceId: user_namespace.id,
              groupOwners: [{
                id: user_namespace_owner.id,
                email: user_namespace_owner.notification_email_for(user_namespace),
                fullName: user_namespace_owner.name
              }],
              maxSeatsUsed: user_namespace_subscription.max_seats_used
            },
            {
              glNamespaceId: group_namespace.id,
              groupOwners: [{
                id: group_namespace_owner.id,
                email: group_namespace_owner.notification_email_for(group_namespace),
                fullName: group_namespace_owner.name
              }],
              maxSeatsUsed: group_namespace_subscription.max_seats_used
            }
          ))

        result = described_class.execute

        expect(result.success?).to be true
        expect(result.message).to eq('Overage notifications sent')
      end
    end

    context 'with no subscriptions' do
      it 'does not send notifications' do
        expect(Gitlab::SubscriptionPortal::Client).not_to receive(:send_seat_overage_notification_batch)

        described_class.execute
      end

      it 'returns success' do
        result = described_class.execute

        expect(result.success?).to be true
      end
    end
  end
end
