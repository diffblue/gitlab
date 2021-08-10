import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const setEnvironmentEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const setStatisticsEndpoint = ({ commit }, endpoint) => {
  commit(`threatMonitoringNetworkPolicy/${types.SET_ENDPOINT}`, endpoint, { root: true });
};

export const requestEnvironments = ({ commit }) => commit(types.REQUEST_ENVIRONMENTS);
export const receiveEnvironmentsSuccess = ({ commit }, environments) =>
  commit(types.RECEIVE_ENVIRONMENTS_SUCCESS, environments);
export const receiveEnvironmentsError = ({ commit }) => {
  commit(types.RECEIVE_ENVIRONMENTS_ERROR);
  createFlash({
    message: s__('ThreatMonitoring|Something went wrong, unable to fetch environments'),
  });
};

const getAllEnvironments = (url, page = 1) =>
  axios
    .get(url, {
      params: {
        per_page: 100,
        page,
      },
    })
    .then(({ headers, data }) => {
      const nextPage = headers && headers['x-next-page'];
      return nextPage
        ? // eslint-disable-next-line promise/no-nesting
          getAllEnvironments(url, nextPage).then((environments) => [
            ...data.environments,
            ...environments,
          ])
        : data.environments;
    });

export const fetchEnvironments = ({ state, dispatch }) => {
  if (!state.environmentsEndpoint) {
    return dispatch('receiveEnvironmentsError');
  }

  dispatch('requestEnvironments');

  return getAllEnvironments(state.environmentsEndpoint)
    .then((environments) => dispatch('receiveEnvironmentsSuccess', environments))
    .catch(() => dispatch('receiveEnvironmentsError'));
};

export const setCurrentEnvironmentId = ({ commit }, environmentId) => {
  commit(types.SET_CURRENT_ENVIRONMENT_ID, environmentId);
};

export const setCurrentTimeWindow = ({ commit }, timeWindow) => {
  commit(types.SET_CURRENT_TIME_WINDOW, timeWindow.name);
};

export const setAllEnvironments = ({ commit }) => {
  commit(types.SET_ALL_ENVIRONMENTS);
};
