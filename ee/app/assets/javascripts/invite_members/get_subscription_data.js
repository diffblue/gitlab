import { memoize } from 'lodash';
import Api from 'ee/api';

const isFreeGroup = (plan) => ['free', null].includes(plan.code);

const fetchSubscriptionData = memoize((id) =>
  Api.userSubscription(id).then((response) => response.data),
);

export const fetchSubscription = async (namespaceId) => {
  const data = await fetchSubscriptionData(namespaceId);

  return {
    subscriptionSeats: data.usage.seats_in_subscription,
    // Fetch data in https://gitlab.com/gitlab-org/gitlab/-/issues/354768
    billedUserIds: [],
    billedUserEmails: [],
    maxSeatsUsed: data.usage.max_seats_used,
    seatsInUse: data.usage.seats_in_use,
    isFreeGroup: isFreeGroup(data.plan),
    excludeGuests: data.plan.exclude_guests || false,
  };
};
