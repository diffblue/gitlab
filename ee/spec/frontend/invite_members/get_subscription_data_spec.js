import { mockDataSubscription } from 'ee_jest/billings/mock_data';
import { fetchSubscription } from 'ee/invite_members/get_subscription_data';
import Api from 'ee/api';

jest.mock('ee/api.js', () => ({
  userSubscription: jest
    .fn()
    .mockResolvedValueOnce({ data: mockDataSubscription.gold })
    .mockResolvedValueOnce({ data: mockDataSubscription.free }),
}));

describe('fetchUserIdsFromGroup', () => {
  it('caches the response for the same input', async () => {
    await fetchSubscription(1);
    await fetchSubscription(1);
    expect(Api.userSubscription).toHaveBeenCalledTimes(1);
  });

  it('returns correct subscription data for paid group', async () => {
    const result = await fetchSubscription(1);
    expect(result).toEqual({
      billedUserEmails: [],
      billedUserIds: [],
      isFreeGroup: false,
      maxSeatsUsed: 104,
      seatsInUse: 98,
      subscriptionSeats: 100,
      excludeGuests: true,
    });
  });

  it('returns correct subscription data for free group', async () => {
    const result = await fetchSubscription(2);
    expect(result).toEqual({
      billedUserEmails: [],
      billedUserIds: [],
      isFreeGroup: true,
      maxSeatsUsed: 5,
      seatsInUse: 0,
      subscriptionSeats: 0,
      excludeGuests: false,
    });
  });
});
