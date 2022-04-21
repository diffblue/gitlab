const generateSubscriptionData = ({
  isFreeGroup = false,
  subscriptionSeats = 1,
  maxSeatsUsed = 0,
  seatsInUse = 0,
  billedUserIds = [],
  billedUserEmails = [],
  excludeGuests = false,
} = {}) => ({
  isFreeGroup,
  subscriptionSeats,
  maxSeatsUsed,
  seatsInUse,
  billedUserIds,
  billedUserEmails,
  excludeGuests,
});

export const generateInvitedUsersData = ({
  isGuestRole = false,
  usersToInviteByEmail = [],
  usersToAddById = [],
} = {}) => ({
  isGuestRole,
  usersToInviteByEmail,
  usersToAddById,
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
export const allowGuestsSubscription = generateSubscriptionData({
  maxSeatsUsed: 1,
  seatsInUse: 1,
  billedUserIds: [1],
  billedUserEmails: ['test@example'],
  excludeGuests: true,
});
