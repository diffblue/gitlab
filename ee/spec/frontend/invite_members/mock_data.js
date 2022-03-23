const generateSubscriptionData = ({
  isFreeGroup = false,
  subscriptionSeats = 1,
  maxSeatsUsed = 0,
  seatsInUse = 0,
  billedUserIds = [],
  billedUserEmails = [],
} = {}) => ({
  isFreeGroup,
  subscriptionSeats,
  maxSeatsUsed,
  seatsInUse,
  billedUserIds,
  billedUserEmails,
});

export const freePlanSubsciption = generateSubscriptionData({ isFreeGroup: true });
export const oneFreeSeatSubscription = generateSubscriptionData();
export const noFreePlacesSubscription = generateSubscriptionData({
  maxSeatsUsed: 1,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
});
export const subscriptionWithOverage = generateSubscriptionData({
  maxSeatsUsed: 2,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
});
