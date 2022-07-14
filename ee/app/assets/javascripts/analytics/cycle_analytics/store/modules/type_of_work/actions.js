import { omit } from 'lodash';
import Api from 'ee/api';
import { __ } from '~/locale';
import { throwIfUserForbidden, checkForDataError, flashErrorIfStatusNotOk } from '../../../utils';
import * as types from './mutation_types';

export const setLoading = ({ commit }, loading) => commit(types.SET_LOADING, loading);

export const receiveTopRankedGroupLabelsSuccess = ({ commit, dispatch }, data) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS, data);
  dispatch('fetchTasksByTypeData');
};

export const receiveTopRankedGroupLabelsError = ({ commit }, error) => {
  flashErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching the top labels for the selected group'),
  });
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR, error);
};

export const fetchTopRankedGroupLabels = ({ dispatch, commit, state, rootGetters }) => {
  commit(types.REQUEST_TOP_RANKED_GROUP_LABELS);
  const {
    currentGroupPath,
    cycleAnalyticsRequestParams: {
      project_ids,
      created_after,
      created_before,
      author_username,
      milestone_title,
      assignee_username,
    },
  } = rootGetters;
  const { subject } = state;

  return Api.cycleAnalyticsTopLabels(currentGroupPath, {
    subject,
    project_ids,
    created_after,
    created_before,
    author_username,
    milestone_title,
    assignee_username,
  })
    .then(checkForDataError)
    .then(({ data }) => dispatch('receiveTopRankedGroupLabelsSuccess', data))
    .catch((error) => {
      throwIfUserForbidden(error);
      return dispatch('receiveTopRankedGroupLabelsError', error);
    });
};

export const receiveTasksByTypeDataError = ({ commit }, error) => {
  flashErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching data for the tasks by type chart'),
  });
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR, error);
};

export const fetchTasksByTypeData = ({ dispatch, commit, state, rootGetters, getters }) => {
  const { currentGroupPath, cycleAnalyticsRequestParams } = rootGetters;
  const { subject = [] } = state;
  const { selectedLabelIds = [] } = getters;

  // ensure we clear any chart data currently in state
  commit(types.REQUEST_TASKS_BY_TYPE_DATA);

  return Api.cycleAnalyticsTasksByType(currentGroupPath, {
    ...omit(cycleAnalyticsRequestParams, ['label_name']),
    label_ids: selectedLabelIds,
    subject,
  })
    .then(checkForDataError)
    .then(({ data }) => commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, data))
    .catch((error) => dispatch('receiveTasksByTypeDataError', error));
};

export const setTasksByTypeFilters = ({ dispatch, commit }, data) => {
  commit(types.SET_TASKS_BY_TYPE_FILTERS, data);
  dispatch('fetchTasksByTypeData');
};
