import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';

const GROUP_PATH = '/groups/:id';
const GROUP_ANALYTICS_PATH = `${GROUP_PATH}/-/analytics`;
const GROUP_VALUE_STREAMS_PATH = `${GROUP_ANALYTICS_PATH}/value_stream_analytics/value_streams`;
const GROUP_SELECTED_VALUE_STREAM_PATH = `${GROUP_VALUE_STREAMS_PATH}/:value_stream_id`;
const GROUP_VALUE_STREAM_STAGE_PATH = `${GROUP_SELECTED_VALUE_STREAM_PATH}/stages/:stage_id`;

const buildGroupPath = ({ groupId }) => buildApiUrl(GROUP_PATH).replace(':id', groupId);

const buildGroupAnalyticsPath = ({ groupId }) =>
  buildApiUrl(GROUP_ANALYTICS_PATH).replace(':id', groupId);

const buildGroupValueStreamRootPath = ({ groupId }) =>
  buildApiUrl(GROUP_VALUE_STREAMS_PATH).replace(':id', groupId);

const buildGroupValueStreamPath = ({ groupId, valueStreamId = null }) =>
  buildApiUrl(GROUP_SELECTED_VALUE_STREAM_PATH)
    .replace(':id', groupId)
    .replace(':value_stream_id', valueStreamId);

const buildGroupValueStreamStagePath = ({ groupId, valueStreamId = null, stageId = null }) =>
  buildApiUrl(GROUP_VALUE_STREAM_STAGE_PATH)
    .replace(':id', groupId)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getGroupValueStreamStageMedian = (
  { groupId, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildGroupValueStreamStagePath({ groupId, valueStreamId, stageId });
  return axios.get(`${stageBase}/median`, { params });
};

export const getGroupValueStreamMetrics = ({
  endpoint = METRIC_TYPE_SUMMARY,
  requestPath: groupId,
  params = {},
}) =>
  axios.get(joinPaths(buildGroupAnalyticsPath({ groupId }), 'value_stream_analytics', endpoint), {
    params,
  });

export const getTypeOfWorkTasksByType = (groupId, params = {}) => {
  const endpoint = '/type_of_work/tasks_by_type';
  const url = joinPaths(buildGroupAnalyticsPath({ groupId }), endpoint);

  return axios.get(url, { params });
};

export const getTypeOfWorkTopLabels = (groupId, params = {}) => {
  const endpoint = '/type_of_work/tasks_by_type/top_labels';
  const url = joinPaths(buildGroupAnalyticsPath({ groupId }), endpoint);

  return axios.get(url, { params });
};

export const getGroupStagesAndEvents = ({ groupId, valueStreamId, params = {} }) => {
  const endpoint = '/stages';
  const url = joinPaths(buildGroupValueStreamPath({ groupId, valueStreamId }), endpoint);

  return axios.get(url, { params });
};

const stageUrl = ({ groupId, valueStreamId, stageId }) => {
  return buildGroupValueStreamStagePath({ groupId, valueStreamId, stageId });
};

export const getStageEvents = ({ groupId, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ groupId, valueStreamId, stageId });
  const url = `${stageBase}/records`;
  return axios.get(url, { params });
};

export const getStageCount = ({ groupId, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ groupId, valueStreamId, stageId });
  const url = `${stageBase}/count`;
  return axios.get(url, { params });
};

export const createValueStream = (groupId, data) => {
  const url = buildGroupValueStreamRootPath({ groupId });
  return axios.post(url, data);
};

export const updateValueStream = ({ groupId, valueStreamId, data }) => {
  const url = buildGroupValueStreamPath({ groupId, valueStreamId });
  return axios.put(url, data);
};

export const deleteValueStream = (groupId, valueStreamId) => {
  const url = buildGroupValueStreamPath({ groupId, valueStreamId });
  return axios.delete(url);
};

export const getValueStreams = (groupId, data) => {
  const url = buildGroupValueStreamRootPath({ groupId });
  return axios.get(url, data);
};

export const getDurationChart = ({ groupId, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ groupId, valueStreamId, stageId });
  const url = `${stageBase}/average_duration_chart`;
  return axios.get(url, { params });
};

export const getGroupLabels = (groupId, params = { search: null }) => {
  // TODO: This can be removed when we resolve the labels endpoint
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25746
  const endpoint = '/-/labels.json';
  const url = joinPaths(buildGroupPath({ groupId }), endpoint);

  return axios.get(url, {
    params,
  });
};
