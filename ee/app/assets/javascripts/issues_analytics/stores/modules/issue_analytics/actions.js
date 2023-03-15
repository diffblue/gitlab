import { createAlert } from '~/alert';
import { __ } from '~/locale';
import service from '../../../services/issue_analytics_service';
import * as types from './mutation_types';

export const setFilters = ({ commit }, value) => {
  commit(types.SET_FILTERS, value);
};

export const setLoadingState = ({ commit }, value) => {
  commit(types.SET_LOADING_STATE, value);
};

export const fetchChartData = ({ commit, dispatch, getters }, endpoint) => {
  dispatch('setLoadingState', true);

  return service
    .fetchChartData(endpoint, getters.appliedFilters)
    .then((res) => res.data)
    .then((data) => commit(types.SET_CHART_DATA, data))
    .then(() => dispatch('setLoadingState', false))
    .catch(() =>
      createAlert({
        message: __('An error occurred while loading chart data'),
      }),
    );
};
