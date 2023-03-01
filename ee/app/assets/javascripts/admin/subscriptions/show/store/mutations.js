import * as types from './mutation_types';

export default {
  [types.REQUEST_SYNC](state, payload) {
    state.subscriptionSyncStatus = payload;
    state.breakdown.hasAsyncActivity = true;
  },
  [types.RECEIVE_SYNC_ERROR](state, payload) {
    state.subscriptionSyncStatus = payload;
    state.breakdown.hasAsyncActivity = false;
    state.breakdown.shouldShowNotifications = true;
  },
  [types.RECEIVE_SYNC_SUCCESS](state, payload) {
    state.subscriptionSyncStatus = payload;
    state.breakdown.hasAsyncActivity = false;
    state.breakdown.shouldShowNotifications = true;
  },
  [types.REQUEST_REMOVE_LICENSE](state) {
    state.breakdown.hasAsyncActivity = true;
  },
  [types.RECEIVE_REMOVE_LICENSE_ERROR](state, payload) {
    state.breakdown.hasAsyncActivity = false;
    state.breakdown.licenseError = payload;
  },
  [types.RECEIVE_REMOVE_LICENSE_SUCCESS](state) {
    state.breakdown.hasAsyncActivity = false;
  },
  [types.REQUEST_DISMISS_ALERT](state) {
    state.breakdown.shouldShowNotifications = false;
    state.breakdown.licenseError = null;
  },
};
