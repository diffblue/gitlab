import getters from 'ee/admin/subscriptions/show/store/getters';
import { subscriptionSyncStatus } from 'ee/admin/subscriptions/show/constants';

describe('Admin Subscriptions Show Getters', () => {
  let state;

  beforeEach(() => {
    state = { subscriptionSyncStatus: null };
  });

  describe('didSyncFail', () => {
    it.each([
      [true, subscriptionSyncStatus.SYNC_FAILURE],
      [false, subscriptionSyncStatus.SYNC_PENDING],
      [false, null],
    ])('returns %s when subscriptionSyncStatus is %s', (expected, syncStatus) => {
      state.subscriptionSyncStatus = syncStatus;

      expect(getters.didSyncFail(state)).toBe(expected);
    });
  });

  describe('isSyncPending', () => {
    it.each([
      [false, subscriptionSyncStatus.SYNC_FAILURE],
      [true, subscriptionSyncStatus.SYNC_PENDING],
      [false, null],
    ])('returns %s when subscriptionSyncStatus is %s', (expected, syncStatus) => {
      state = { subscriptionSyncStatus: syncStatus };

      expect(getters.isSyncPending(state)).toBe(expected);
    });
  });
});
