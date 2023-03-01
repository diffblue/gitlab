import axios from 'axios';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { subscriptionSyncStatus } from '../constants';
import * as types from './mutation_types';

export const syncSubscription = async ({ commit, state }) => {
  commit(types.REQUEST_SYNC, subscriptionSyncStatus.SYNC_PENDING);

  try {
    await axios.post(state.paths.subscriptionSyncPath);
    commit(types.RECEIVE_SYNC_SUCCESS, subscriptionSyncStatus.SYNC_SUCCESS);
  } catch (e) {
    commit(types.RECEIVE_SYNC_ERROR, subscriptionSyncStatus.SYNC_FAILURE);
  }
};
export const removeLicense = async ({ commit, dispatch, state }) => {
  commit(types.REQUEST_REMOVE_LICENSE);

  try {
    await axios.delete(state.paths.licenseRemovalPath);
    dispatch('removeLicenseSuccess');
  } catch (e) {
    commit(types.RECEIVE_REMOVE_LICENSE_ERROR, e);
  }
};

export const removeLicenseSuccess = ({ commit }) => {
  commit(types.RECEIVE_REMOVE_LICENSE_SUCCESS);

  refreshCurrentPage();
};

export const dismissAlert = ({ commit }) => {
  commit(types.REQUEST_DISMISS_ALERT);
};
