import Api from 'ee/api';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const setNamespaceId = ({ commit }, namespaceId) => {
  commit(types.SET_NAMESPACE_ID, namespaceId);
};

/**
 * Subscription Table
 */
export const fetchSubscription = ({ dispatch, state }) => {
  dispatch('requestSubscription');

  return Api.userSubscription(state.namespaceId)
    .then(({ data }) => dispatch('receiveSubscriptionSuccess', data))
    .catch(() => dispatch('receiveSubscriptionError'));
};

export const requestSubscription = ({ commit }) => commit(types.REQUEST_SUBSCRIPTION);

export const receiveSubscriptionSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_SUBSCRIPTION_SUCCESS, response);

export const receiveSubscriptionError = ({ commit }) => {
  createAlert({
    message: s__('SubscriptionTable|An error occurred while loading the subscription details.'),
  });
  commit(types.RECEIVE_SUBSCRIPTION_ERROR);
};
