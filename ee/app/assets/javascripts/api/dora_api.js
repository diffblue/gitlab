import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

export const DEPLOYMENT_FREQUENCY_METRIC_TYPE = 'deployment_frequency';
export const LEAD_TIME_FOR_CHANGES = 'lead_time_for_changes';
export const TIME_TO_RESTORE_SERVICE = 'time_to_restore_service';
export const CHANGE_FAILURE_RATE = 'change_failure_rate';
export const ALL_METRIC_TYPES = Object.freeze([
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
  CHANGE_FAILURE_RATE,
]);

export const PROJECTS_DORA_METRICS_PATH = '/api/:version/projects/:id/dora/metrics';
export const GROUPS_DORA_METRICS_PATH = '/api/:version/groups/:id/dora/metrics';

function getDoraMetrics(apiUrl, projectOrGroupId, metric, params) {
  if (!ALL_METRIC_TYPES.includes(metric)) {
    throw new Error(`Unsupported metric type: "${metric}"`);
  }

  const url = buildApiUrl(apiUrl).replace(':id', encodeURIComponent(projectOrGroupId));

  return axios.get(url, {
    params: {
      metric,
      ...params,
    },
  });
}

/**
 * Gets DORA 4 metrics data from a project
 * See https://docs.gitlab.com/ee/api/dora/metrics.html#get-project-level-dora-metrics
 *
 * @param {String|Number} projectId The ID or path of the project
 * @param {String} metric The name of the metric to fetch. Must be one of:
 * `["deployment_frequency", "lead_time_for_changes"]`
 * @param {Object} params Any additional query parameters that should be
 * included with the request. These parameters are optional. See
 * https://docs.gitlab.com/ee/api/dora/metrics.html for a list of available options.
 *
 * @returns {Promise} A `Promise` that resolves to an array of data points.
 */
export function getProjectDoraMetrics(projectId, metric, params = {}) {
  return getDoraMetrics(PROJECTS_DORA_METRICS_PATH, projectId, metric, params);
}

/**
 * Gets DORA 4 metrics data from a group
 * See https://docs.gitlab.com/ee/api/dora/metrics.html#get-group-level-dora-metrics
 *
 * @param {String|Number} groupId The ID or path of the group
 * @param {String} metric The name of the metric to fetch. Must be one of:
 * `["deployment_frequency", "lead_time_for_changes"]`
 * @param {Object} params Any additional query parameters that should be
 * included with the request. These parameters are optional. See
 * https://docs.gitlab.com/ee/api/dora/metrics.html for a list of available options.
 *
 * @returns {Promise} A `Promise` that resolves to an array of data points.
 */
export function getGroupDoraMetrics(groupId, metric, params = {}) {
  return getDoraMetrics(GROUPS_DORA_METRICS_PATH, groupId, metric, params);
}
