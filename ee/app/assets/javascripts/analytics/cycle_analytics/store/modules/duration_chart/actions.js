import { getDurationChart } from 'ee/api/analytics_api';
import { __ } from '~/locale';
import { checkForDataError, flashErrorIfStatusNotOk } from '../../../utils';
import * as types from './mutation_types';

export const setLoading = ({ commit }, loading) => commit(types.SET_LOADING, loading);

export const requestDurationData = ({ commit }) => commit(types.REQUEST_DURATION_DATA);

export const receiveDurationDataError = ({ commit }, error) => {
  flashErrorIfStatusNotOk({
    error,
    message: __('There was an error while fetching value stream analytics duration data.'),
  });
  commit(types.RECEIVE_DURATION_DATA_ERROR, error);
};

export const fetchDurationData = ({ dispatch, commit, rootGetters }) => {
  dispatch('requestDurationData');
  const {
    cycleAnalyticsRequestParams,
    activeStages,
    currentGroupPath,
    currentValueStreamId,
  } = rootGetters;
  return Promise.all(
    activeStages.map((stage) => {
      const { id } = stage;

      return getDurationChart({
        groupId: currentGroupPath,
        valueStreamId: currentValueStreamId,
        stageId: id,
        params: cycleAnalyticsRequestParams,
      })
        .then(checkForDataError)
        .then(({ data }) => ({ id, selected: true, data }));
    }),
  )
    .then((data) => commit(types.RECEIVE_DURATION_DATA_SUCCESS, data))
    .catch((error) => dispatch('receiveDurationDataError', error));
};
