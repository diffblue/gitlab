import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { PAGE_SIZE } from 'ee/threat_monitoring/constants';
import * as types from './mutation_types';

export const setEnvironmentEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const setHasEnvironment = ({ commit }, data) => {
  commit(types.SET_HAS_ENVIRONMENT, data);
};

export const setStatisticsEndpoint = ({ commit }, endpoint) => {
  commit(`threatMonitoringNetworkPolicy/${types.SET_ENDPOINT}`, endpoint, { root: true });
};

export const requestEnvironments = ({ commit }) => commit(types.REQUEST_ENVIRONMENTS);
export const receiveEnvironmentsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_ENVIRONMENTS_SUCCESS, data);
export const receiveEnvironmentsError = ({ commit }) => {
  commit(types.RECEIVE_ENVIRONMENTS_ERROR);
  createFlash({
    message: s__('ThreatMonitoring|Something went wrong, unable to fetch environments'),
  });
};

const getEnvironments = async (url, page = 1) => {
  try {
    const { data, headers } = await axios.get(url, {
      params: {
        per_page: PAGE_SIZE,
        page,
      },
    });

    const { nextPage } = parseIntPagination(normalizeHeaders(headers));
    return { environments: data.environments, nextPage };
  } catch {
    throw new Error();
  }
};

export const fetchEnvironments = async ({ state, dispatch }) => {
  if (!state.environmentsEndpoint) {
    return dispatch('receiveEnvironmentsError');
  }

  dispatch('requestEnvironments');

  try {
    const data = await getEnvironments(state.environmentsEndpoint, state.nextPage);

    return dispatch('receiveEnvironmentsSuccess', {
      environments: [...state.environments, ...data.environments],
      nextPage: data.nextPage,
    });
  } catch {
    return dispatch('receiveEnvironmentsError');
  }
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
