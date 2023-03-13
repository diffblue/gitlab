import { getTypeOfWorkTopLabels, getTypeOfWorkTasksByType } from 'ee/api/analytics_api';
import { __ } from '~/locale';
import { throwIfUserForbidden, checkForDataError, alertErrorIfStatusNotOk } from '../../../utils';
import * as types from './mutation_types';

export const setLoading = ({ commit }, loading) => commit(types.SET_LOADING, loading);

export const receiveTopRankedGroupLabelsSuccess = ({ commit, dispatch }, data) => {
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_SUCCESS, data);
  dispatch('fetchTasksByTypeData');
};

export const receiveTopRankedGroupLabelsError = ({ commit }, error) => {
  alertErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching the top labels for the selected group'),
  });
  commit(types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR, error);
};

export const fetchTopRankedGroupLabels = ({ dispatch, commit, state, rootGetters }) => {
  commit(types.REQUEST_TOP_RANKED_GROUP_LABELS);
  const {
    namespacePath,
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

  return getTypeOfWorkTopLabels(namespacePath, {
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
  alertErrorIfStatusNotOk({
    error,
    message: __('There was an error fetching data for the tasks by type chart'),
  });
  commit(types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR, error);
};

export const fetchTasksByTypeData = ({ dispatch, commit, state, rootGetters, getters }) => {
  const { namespacePath, cycleAnalyticsRequestParams } = rootGetters;
  const { subject } = state;
  const { selectedLabelNames } = getters;

  const {
    project_ids,
    created_after,
    created_before,
    author_username,
    milestone_title,
    assignee_username,
  } = cycleAnalyticsRequestParams;

  // ensure we clear any chart data currently in state
  commit(types.REQUEST_TASKS_BY_TYPE_DATA);

  // dont request if we have no labels selected...for now
  if (selectedLabelNames.length) {
    return getTypeOfWorkTasksByType(namespacePath, {
      project_ids,
      created_after,
      created_before,
      author_username,
      milestone_title,
      assignee_username,
      subject,
      // NOTE: the type of work module will continute to manage its labels, ignoring the filter bar labels
      // until we resolve: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34524
      label_names: selectedLabelNames,
    })
      .then(checkForDataError)
      .then(({ data }) => commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, data))
      .catch((error) => dispatch('receiveTasksByTypeDataError', error));
  }
  return commit(types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS, []);
};

export const setTasksByTypeFilters = ({ dispatch, commit }, data) => {
  commit(types.SET_TASKS_BY_TYPE_FILTERS, data);
  dispatch('fetchTasksByTypeData');
};
