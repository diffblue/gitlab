import { METRIC_TYPE_SUMMARY } from '~/api/analytics_api';
import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';

const NAMESPACE_PATH = '/:namespace_path';
const NAMESPACE_ANALYTICS_PATH = `${NAMESPACE_PATH}/-/analytics`;
const NAMESPACE_VALUE_STREAMS_PATH = `${NAMESPACE_ANALYTICS_PATH}/value_stream_analytics/value_streams`;
const NAMESPACE_SELECTED_VALUE_STREAM_PATH = `${NAMESPACE_VALUE_STREAMS_PATH}/:value_stream_id`;
const NAMESPACE_VALUE_STREAM_STAGE_PATH = `${NAMESPACE_SELECTED_VALUE_STREAM_PATH}/stages/:stage_id`;

const buildPath = ({ namespacePath }) =>
  buildApiUrl(NAMESPACE_PATH).replace(':namespace_path', namespacePath);

const buildAnalyticsPath = ({ namespacePath }) =>
  buildApiUrl(NAMESPACE_ANALYTICS_PATH).replace(':namespace_path', namespacePath);

const buildValueStreamRootPath = ({ namespacePath }) =>
  buildApiUrl(NAMESPACE_VALUE_STREAMS_PATH).replace(':namespace_path', namespacePath);

const buildValueStreamPath = ({ namespacePath, valueStreamId = null }) =>
  buildApiUrl(NAMESPACE_SELECTED_VALUE_STREAM_PATH)
    .replace(':namespace_path', namespacePath)
    .replace(':value_stream_id', valueStreamId);

const buildValueStreamStagePath = ({ namespacePath, valueStreamId = null, stageId = null }) =>
  buildApiUrl(NAMESPACE_VALUE_STREAM_STAGE_PATH)
    .replace(':namespace_path', namespacePath)
    .replace(':value_stream_id', valueStreamId)
    .replace(':stage_id', stageId);

export const getValueStreamStageMedian = (
  { namespacePath, valueStreamId, stageId },
  params = {},
) => {
  const stageBase = buildValueStreamStagePath({ namespacePath, valueStreamId, stageId });
  return axios.get(`${stageBase}/median`, { params });
};

export const getValueStreamMetrics = ({
  endpoint = METRIC_TYPE_SUMMARY,
  requestPath: namespacePath,
  params = {},
}) =>
  axios.get(joinPaths(buildAnalyticsPath({ namespacePath }), 'value_stream_analytics', endpoint), {
    params,
  });

export const getTypeOfWorkTasksByType = (namespacePath, params = {}) => {
  const endpoint = '/type_of_work/tasks_by_type';
  const url = joinPaths(buildAnalyticsPath({ namespacePath }), endpoint);

  return axios.get(url, { params });
};

export const getTypeOfWorkTopLabels = (namespacePath, params = {}) => {
  const endpoint = '/type_of_work/tasks_by_type/top_labels';
  const url = joinPaths(buildAnalyticsPath({ namespacePath }), endpoint);

  return axios.get(url, { params });
};

export const getStagesAndEvents = ({ namespacePath, valueStreamId, params = {} }) => {
  const endpoint = '/stages';
  const url = joinPaths(buildValueStreamPath({ namespacePath, valueStreamId }), endpoint);

  return axios.get(url, { params });
};

const stageUrl = ({ namespacePath, valueStreamId, stageId }) => {
  return buildValueStreamStagePath({ namespacePath, valueStreamId, stageId });
};

export const getStageEvents = ({ namespacePath, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ namespacePath, valueStreamId, stageId });
  const url = `${stageBase}/records`;
  return axios.get(url, { params });
};

export const getStageCount = ({ namespacePath, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ namespacePath, valueStreamId, stageId });
  const url = `${stageBase}/count`;
  return axios.get(url, { params });
};

export const createValueStream = (namespacePath, data) => {
  const url = buildValueStreamRootPath({ namespacePath });
  return axios.post(url, data);
};

export const updateValueStream = ({ namespacePath, valueStreamId, data }) => {
  const url = buildValueStreamPath({ namespacePath, valueStreamId });
  return axios.put(url, data);
};

export const deleteValueStream = (namespacePath, valueStreamId) => {
  const url = buildValueStreamPath({ namespacePath, valueStreamId });
  return axios.delete(url);
};

export const getValueStreams = (namespacePath, data) => {
  const url = buildValueStreamRootPath({ namespacePath });
  return axios.get(url, data);
};

export const getDurationChart = ({ namespacePath, valueStreamId, stageId, params = {} }) => {
  const stageBase = stageUrl({ namespacePath, valueStreamId, stageId });
  const url = `${stageBase}/average_duration_chart`;
  return axios.get(url, { params });
};

export const getGroupLabels = (namespacePath, params = { search: null }) => {
  // TODO: This can be removed when we resolve the labels endpoint
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25746
  const endpoint = '/-/labels.json';
  const url = joinPaths(buildPath({ namespacePath }), endpoint);

  return axios.get(url, {
    params,
  });
};
