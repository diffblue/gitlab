import {
  createValueStream as apiCreateValueStream,
  updateValueStream as apiUpdateValueStream,
  deleteValueStream as apiDeleteValueStream,
  getValueStreams,
} from 'ee/api/analytics_api';
import { FETCH_VALUE_STREAM_DATA } from '../../constants';
import * as types from '../mutation_types';

export const receiveCreateValueStreamSuccess = ({ commit }, valueStream = {}) => {
  commit(types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS, valueStream);
  commit(types.SET_CREATING_AGGREGATION, true);
};

export const createValueStream = ({ commit, dispatch, getters }, data) => {
  const { namespacePath } = getters;
  commit(types.REQUEST_CREATE_VALUE_STREAM);

  return apiCreateValueStream(namespacePath, data)
    .then(({ data: newValueStream }) => dispatch('receiveCreateValueStreamSuccess', newValueStream))
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_CREATE_VALUE_STREAM_ERROR, { message, errors, data });
    });
};

export const updateValueStream = (
  { commit, dispatch, getters },
  { id: valueStreamId, ...data },
) => {
  const { namespacePath } = getters;
  commit(types.REQUEST_UPDATE_VALUE_STREAM);

  return apiUpdateValueStream({ namespacePath, valueStreamId, data })
    .then(({ data: newValueStream }) => {
      commit(types.RECEIVE_UPDATE_VALUE_STREAM_SUCCESS, newValueStream);
      return dispatch('fetchCycleAnalyticsData');
    })
    .catch(({ response } = {}) => {
      const { data: { message, payload: { errors } } = null } = response;
      commit(types.RECEIVE_UPDATE_VALUE_STREAM_ERROR, { message, errors, data });
    });
};

export const deleteValueStream = ({ commit, dispatch, getters }, valueStreamId) => {
  const { namespacePath } = getters;
  commit(types.REQUEST_DELETE_VALUE_STREAM);

  return apiDeleteValueStream(namespacePath, valueStreamId)
    .then(() => commit(types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS))
    .then(() => dispatch('fetchCycleAnalyticsData'))
    .catch(({ response } = {}) => {
      const { data: { message } = null } = response;
      commit(types.RECEIVE_DELETE_VALUE_STREAM_ERROR, message);
    });
};

export const fetchValueStreamData = ({ dispatch }) =>
  Promise.resolve()
    .then(() => dispatch('fetchGroupStagesAndEvents'))
    .then(() => dispatch('fetchStageMedianValues'))
    .then(() => dispatch('durationChart/fetchDurationData'));

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return dispatch(FETCH_VALUE_STREAM_DATA);
};

export const receiveValueStreamsSuccess = (
  { state: { selectedValueStream = null }, commit, dispatch },
  data = [],
) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);

  if (!selectedValueStream && !data.length) {
    return dispatch('fetchGroupStagesAndEvents');
  }

  if (!selectedValueStream && data.length) {
    const [firstStream] = data;
    return Promise.resolve()
      .then(() => dispatch('setSelectedValueStream', firstStream))
      .then(() => dispatch('fetchStageCountValues'));
  }

  return Promise.resolve()
    .then(() => dispatch(FETCH_VALUE_STREAM_DATA))
    .then(() => dispatch('fetchStageCountValues'));
};

export const fetchValueStreams = ({ commit, dispatch, getters }) => {
  const { namespacePath } = getters;

  commit(types.REQUEST_VALUE_STREAMS);

  return getValueStreams(namespacePath)
    .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
    .catch((error) => {
      const {
        response: { status },
      } = error;
      commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
      throw error;
    });
};
