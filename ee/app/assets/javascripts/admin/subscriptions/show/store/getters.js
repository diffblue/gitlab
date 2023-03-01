import { subscriptionSyncStatus } from '../constants';

export default {
  didSyncFail: (state) => state.subscriptionSyncStatus === subscriptionSyncStatus.SYNC_FAILURE,
  didSyncSucceed: (state) => state.subscriptionSyncStatus === subscriptionSyncStatus.SYNC_SUCCESS,
};
