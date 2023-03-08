import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

import { FETCH_ERROR_MESSAGE, SORT_BY, SORT_ORDER } from './constants';
import * as types from './mutation_types';

export const setLicensesEndpoint = ({ commit }, endpoint) =>
  commit(types.SET_LICENSES_ENDPOINT, endpoint);

export const fetchLicenses = ({ state, dispatch }, params = {}) => {
  if (!state.endpoint) {
    return Promise.reject(new Error(__('No endpoint provided')));
  }

  dispatch('requestLicenses');

  return axios
    .get(state.endpoint, {
      params: {
        per_page: 10,
        page: state.pageInfo.page || 1,
        sort_by: SORT_BY.CLASSIFICATION,
        sort_direction: SORT_ORDER.DESC,
        ...params,
      },
    })
    .then((response) => {
      dispatch('receiveLicensesSuccess', response);
    })
    .catch((error) => {
      dispatch('receiveLicensesError', error);
    });
};

export const requestLicenses = ({ commit }) => commit(types.REQUEST_LICENSES);

export const receiveLicensesSuccess = ({ commit }, { headers, data }) => {
  const normalizedHeaders = normalizeHeaders(headers);
  const pageInfo = parseIntPagination(normalizedHeaders);
  const { licenses, report: reportInfo } = data;

  commit(types.RECEIVE_LICENSES_SUCCESS, { licenses, reportInfo, pageInfo });
};

export const receiveLicensesError = ({ commit }) => {
  commit(types.RECEIVE_LICENSES_ERROR);
  createAlert({
    message: FETCH_ERROR_MESSAGE,
  });
};
