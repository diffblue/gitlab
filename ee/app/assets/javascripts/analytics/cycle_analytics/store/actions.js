import { getGroupLabels } from 'ee/api/analytics_api';
import { removeFlash } from '~/analytics/shared/utils';
import { createAlert } from '~/alert';
import { constructPathWithNamespace } from '~/analytics/cycle_analytics/utils';
import { LABELS_ENDPOINT, MILESTONES_ENDPOINT } from '~/analytics/cycle_analytics/constants';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { __ } from '~/locale';
import * as types from './mutation_types';

export * from './actions/filters';
export * from './actions/stages';
export * from './actions/value_streams';

export const setPaths = ({
  dispatch,
  state: { namespace, groupPath },
  getters: { isProjectNamespace },
}) => {
  const projectPaths = isProjectNamespace
    ? {
        projectEndpoint: namespace.fullPath,
      }
    : {};

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: constructPathWithNamespace(namespace, LABELS_ENDPOINT),
    milestonesEndpoint: constructPathWithNamespace(namespace, MILESTONES_ENDPOINT),
    groupEndpoint: groupPath,
    ...projectPaths,
  });
};

export const setFeatures = ({ commit }, features) => commit(types.SET_FEATURES, features);

export const fetchGroupLabels = ({ commit, getters: { namespacePath } }) => {
  commit(types.REQUEST_GROUP_LABELS);
  return getGroupLabels(namespacePath, { only_group_labels: true })
    .then(({ data = [] }) => commit(types.RECEIVE_GROUP_LABELS_SUCCESS, data))
    .catch(() => commit(types.RECEIVE_GROUP_LABELS_ERROR));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_VALUE_STREAM_DATA);

export const receiveCycleAnalyticsDataSuccess = ({
  commit,
  dispatch,
  state: { enableTasksByTypeChart },
}) => {
  commit(types.RECEIVE_VALUE_STREAM_DATA_SUCCESS);

  if (enableTasksByTypeChart) {
    dispatch('typeOfWork/fetchTopRankedGroupLabels');
  }
};

export const receiveCycleAnalyticsDataError = ({ commit }, { response = {} }) => {
  const { status = HTTP_STATUS_INTERNAL_SERVER_ERROR } = response;

  commit(types.RECEIVE_VALUE_STREAM_DATA_ERROR, status);
  if (status !== HTTP_STATUS_FORBIDDEN) {
    createAlert({
      message: __('There was an error while fetching value stream analytics data.'),
    });
  }
};

export const fetchCycleAnalyticsData = ({ dispatch, state: { enableTasksByTypeChart } }) => {
  removeFlash();

  return Promise.resolve()
    .then(() => dispatch('requestCycleAnalyticsData'))
    .then(() => dispatch('fetchValueStreams'))
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch((error) => {
      const promises = [
        dispatch('receiveCycleAnalyticsDataError', error),
        dispatch('durationChart/setLoading', false),
      ];

      if (enableTasksByTypeChart) {
        promises.push(dispatch('typeOfWork/setLoading', false));
      }

      return Promise.all(promises);
    });
};

export const initializeCycleAnalyticsSuccess = ({ commit }) =>
  commit(types.INITIALIZE_VALUE_STREAM_SUCCESS);

export const initializeCycleAnalytics = ({ dispatch, commit }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  const {
    features = {},
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    stage: selectedStage,
    namespace,
    enableTasksByTypeChart,
  } = initialData;
  commit(types.SET_FEATURES, features);

  if (namespace?.fullPath) {
    let promises = [
      dispatch('setPaths', { namespacePath: namespace.fullPath }),
      dispatch('filters/initialize', {
        selectedAuthor,
        selectedMilestone,
        selectedAssigneeList,
        selectedLabelList,
      }),
      dispatch('durationChart/setLoading', true),
    ];

    if (enableTasksByTypeChart) {
      promises = [...promises, dispatch('typeOfWork/setLoading', true)];
    }

    if (selectedStage) {
      promises = [dispatch('setSelectedStage', selectedStage), ...promises];
    } else {
      promises = [dispatch('setDefaultSelectedStage'), ...promises];
    }

    return Promise.all(promises)
      .then(() =>
        Promise.all([
          selectedStage?.id ? dispatch('fetchStageData', selectedStage.id) : Promise.resolve(),
          dispatch('fetchCycleAnalyticsData'),
        ]),
      )
      .then(() => dispatch('initializeCycleAnalyticsSuccess'));
  }

  return dispatch('initializeCycleAnalyticsSuccess');
};
