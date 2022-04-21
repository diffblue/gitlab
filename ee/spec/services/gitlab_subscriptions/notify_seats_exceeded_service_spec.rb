# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::NotifySeatsExceededService, :saas do
  describe '#execute' do
    context 'when the supplied group is a subgroup' do
      it 'returns the relevant error response' do
        group = build(:group, :nested)

        expect(described_class.new(group).execute)
          .to have_attributes(status: :error, message: 'Namespace is not a top level group')
      end
    end

    context 'when the supplied group does not have a subscription' do
      it 'returns the relevant error response' do
        group = build(:group)

        expect(described_class.new(group).execute)
          .to have_attributes(status: :error, message: 'No subscription found for namespace')
      end
    end

    context 'when the group has not exceeded the purchased seats' do
      it 'returns the relevant error response' do
        group = create(:group)
        create(:gitlab_subscription, namespace: group)

        expect(described_class.new(group).execute)
          .to have_attributes(status: :error, message: 'No seat overage')
      end
    end

    context 'when the top level group has exceeded its purchased seats' do
      let_it_be(:group) { create(:group) }
      let_it_be(:owner_1) { create(:user) }
      let_it_be(:owner_2) { create(:user) }

      before do
        create(:gitlab_subscription, namespace: group, seats: 1)

        group.add_owner(owner_1)
        group.add_developer(create(:user))
        group.add_owner(owner_2)
      end

      it 'triggers an email to each group owner and returns successfully' do
        expect(Gitlab::SubscriptionPortal::Client)
          .to receive(:send_seat_overage_notification)
          .with(group: group, max_seats_used: 3)
          .and_return({ success: true })

        expect(described_class.new(group).execute)
          .to have_attributes(status: :success, message: 'Overage notification sent')
      end
    end
  end
end
