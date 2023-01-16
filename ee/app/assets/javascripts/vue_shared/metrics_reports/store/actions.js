import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import * as types from './mutation_types';

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const setEndpoint = ({ commit }, endpoint) => commit(types.SET_ENDPOINT, endpoint);

export const requestMetrics = ({ commit }) => commit(types.REQUEST_METRICS);

/**
 * We need to poll the report endpoint while they are being parsed in the Backend.
 * This can take up to one minute.
 *
 * Poll.js will handle etag response.
 * While http status code is 204, it means it's parsing, and we'll keep polling
 * When http status code is 200, it means parsing is done, we can show the results & stop polling
 * When http status code is 500, it means parsing went wrong and we stop polling
 */
export const fetchMetrics = ({ state, dispatch }) => {
  dispatch('requestMetrics');

  eTagPoll = new Poll({
    resource: {
      getMetrics(endpoint) {
        return axios.get(endpoint);
      },
    },
    data: state.endpoint,
    method: 'getMetrics',
    successCallback: ({ status, data }) => dispatch('receiveMetricsSuccess', { status, data }),
    errorCallback: () => dispatch('receiveMetricsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    axios
      .get(state.endpoint)
      .then(({ status, data }) => dispatch('receiveMetricsSuccess', { status, data }))
      .catch(() => dispatch('receiveMetricsError'));
  }

  Visibility.change(() => {
    if (!Visibility.hidden() && state.isLoading) {
      dispatch('restartPolling');
    } else {
      dispatch('stopPolling');
    }
  });
};

export const receiveMetricsSuccess = ({ commit, dispatch }, { status, data }) => {
  if (status === HTTP_STATUS_OK) {
    commit(types.RECEIVE_METRICS_SUCCESS, data);
    dispatch('stopPolling');
  }
};

export const receiveMetricsError = ({ commit, dispatch }) => {
  commit(types.RECEIVE_METRICS_ERROR);
  dispatch('stopPolling');
};
