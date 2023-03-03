import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

import * as types from './mutation_types';

export const requestConfig = ({ commit }) => commit(types.REQUEST_CONFIG);
export const receiveConfigSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_CONFIG_SUCCESS, data);
export const receiveConfigError = ({ commit }, errorMessage) => {
  const error = errorMessage || __('Unknown Error');
  const message = `${__('There was an error fetching configuration for charts')}: ${error}`;
  createAlert({
    message,
  });
  commit(types.RECEIVE_CONFIG_ERROR);
};

export const fetchConfigData = ({ dispatch }, endpoint) => {
  dispatch('requestConfig');

  return axios
    .get(endpoint)
    .then(({ data }) => {
      if (data) {
        dispatch('receiveConfigSuccess', data);
      } else {
        dispatch('receiveConfigError');
      }
    })
    .catch((error) => {
      dispatch('receiveConfigError', error.response.data.message);
    });
};

export const receiveChartDataSuccess = ({ commit }, { chart, data }) =>
  commit(types.RECEIVE_CHART_SUCCESS, { chart, data });
export const receiveChartDataError = ({ commit }, { chart, error }) =>
  commit(types.RECEIVE_CHART_ERROR, { chart, error });

export const fetchChartData = ({ dispatch }, { endpoint, chart }) =>
  axios
    .post(endpoint, chart)
    .then(({ data }) =>
      dispatch('receiveChartDataSuccess', {
        chart,
        data,
      }),
    )
    .catch((error) => {
      let message = `${__('There was an error gathering the chart data')}`;

      if (error.response.data && error.response.data.message) {
        message += `: ${error.response.data.message}`;
      }
      createAlert({
        message,
      });
      dispatch('receiveChartDataError', { chart, error: message });
    });

export const setActiveTab = ({ commit, state }, key) => {
  const { configData } = state;

  if (configData) {
    const page = configData[key];

    if (page) {
      commit(types.SET_ACTIVE_TAB, key);
      commit(types.SET_ACTIVE_PAGE, page);
    } else {
      createAlert({
        message: __('The specified tab is invalid, please select another'),
      });
    }
  }
};

export const initChartData = ({ commit }, keys) => commit(types.INIT_CHART_DATA, keys);
