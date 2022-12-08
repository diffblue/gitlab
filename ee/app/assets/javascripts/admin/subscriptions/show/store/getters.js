import { subscriptionSyncStatus } from '../constants';

export default {
  didSyncFail: (state) => state.subscriptionSyncStatus === subscriptionSyncStatus.SYNC_FAILURE,
  isSyncPending: (state) => state.subscriptionSyncStatus === subscriptionSyncStatus.SYNC_PENDING,
};
