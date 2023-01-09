import Api from 'ee/api';
import { removeFlash } from '~/analytics/shared/utils';
import { createAlert } from '~/flash';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { __ } from '~/locale';
import * as types from './mutation_types';

export * from './actions/filters';
export * from './actions/stages';
export * from './actions/value_streams';

export const setPaths = ({ dispatch }, options) => {
  const { groupPath, milestonesPath = '', labelsPath = '' } = options;

  return dispatch('filters/setEndpoints', {
    labelsEndpoint: labelsPath,
    milestonesEndpoint: milestonesPath,
    groupEndpoint: groupPath,
  });
};

export const setFeatureFlags = ({ commit }, featureFlags) =>
  commit(types.SET_FEATURE_FLAGS, featureFlags);

export const fetchGroupLabels = ({ commit, getters: { currentGroupPath } }) => {
  commit(types.REQUEST_GROUP_LABELS);
  return Api.cycleAnalyticsGroupLabels(currentGroupPath, { only_group_labels: true })
    .then(({ data = [] }) => commit(types.RECEIVE_GROUP_LABELS_SUCCESS, data))
    .catch(() => commit(types.RECEIVE_GROUP_LABELS_ERROR));
};

export const requestCycleAnalyticsData = ({ commit }) => commit(types.REQUEST_VALUE_STREAM_DATA);

export const receiveCycleAnalyticsDataSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_VALUE_STREAM_DATA_SUCCESS);
  dispatch('typeOfWork/fetchTopRankedGroupLabels');
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

export const fetchCycleAnalyticsData = ({ dispatch }) => {
  removeFlash();

  return Promise.resolve()
    .then(() => dispatch('requestCycleAnalyticsData'))
    .then(() => dispatch('fetchValueStreams'))
    .then(() => dispatch('receiveCycleAnalyticsDataSuccess'))
    .catch((error) => {
      return Promise.all([
        dispatch('receiveCycleAnalyticsDataError', error),
        dispatch('durationChart/setLoading', false),
        dispatch('typeOfWork/setLoading', false),
      ]);
    });
};

export const initializeCycleAnalyticsSuccess = ({ commit }) =>
  commit(types.INITIALIZE_VALUE_STREAM_SUCCESS);

export const initializeCycleAnalytics = ({ dispatch, commit }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  const {
    featureFlags = {},
    milestonesPath,
    labelsPath,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    stage: selectedStage,
    group,
  } = initialData;
  commit(types.SET_FEATURE_FLAGS, featureFlags);

  if (group?.fullPath) {
    return Promise.all([
      selectedStage
        ? dispatch('setSelectedStage', selectedStage)
        : dispatch('setDefaultSelectedStage'),
      dispatch('setPaths', { groupPath: group.fullPath, milestonesPath, labelsPath }),
      dispatch('filters/initialize', {
        selectedAuthor,
        selectedMilestone,
        selectedAssigneeList,
        selectedLabelList,
      }),
      dispatch('durationChart/setLoading', true),
      dispatch('typeOfWork/setLoading', true),
    ])
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
