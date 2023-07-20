import { parse } from 'yaml';
import Api from '~/api';
import { formatAsPercentageWithoutSymbol, secondsToDays } from 'ee/dora/components/util';
import { VULNERABILITY_METRICS } from '~/analytics/shared/constants';
import { fetchMetricsData } from '~/analytics/shared/utils';
import { METRICS_REQUESTS } from '~/analytics/cycle_analytics/constants';
import { groupDoraPerformanceScoreCountsByCategory } from './utils';
import {
  TABLE_METRICS,
  UNITS,
  YAML_CONFIG_PATH,
  DORA_PERFORMERS_SCORE_CATEGORIES,
} from './constants';

/**
 * Takes a flat array of metrics and extracts only the DORA metrics,
 * returning and key value object of the resulting metrics
 *
 * Currently DORA metrics are spread across 2 API endpoints, we fetch the data from
 * both then flatten it into a single array. This function takes that single array and
 * extracts the DORA specific metrics into a key value object.
 *
 * @param {Array} metrics - array of all the time / summary metrics
 * @returns {Object} an object with each of the 4 DORA metrics as a key and their relevant data
 */
export const extractDoraMetrics = (metrics = []) =>
  metrics
    .filter(({ identifier }) => Object.keys(TABLE_METRICS).includes(identifier))
    .reduce((acc, curr) => {
      return {
        ...acc,
        [curr.identifier]: curr,
      };
    }, {});

/**
 * @typedef {Object} ValueStreamDashboardTableMetric
 * @property {String} identifier - Identifier for the specified metric
 * @property {String} value - Display friendly value
 */

/**
 * @typedef {Object} VulnerabilityCountItem
 * @property {String} date - ISO 8601 date
 * @property {Integer} critical - Critical vulnerabilites at that point in time
 * @property {Integer} high - High vulnerabilites at that point in time
 */

/**
 * @typedef {Object} VulnerabilityCountResponseItem
 * @property {ValueStreamDashboardTableMetric} vulnerability_critical - Critical vulnerability count
 * @property {ValueStreamDashboardTableMetric} vulnerability_high - High vulnerability count
 */

/**
 * Takes the raw Query.vulnerabilitiesCountByDay graphql response and prepares the data for display
 * in the Value streams dashboard.
 *
 * An array is returned, but we only want the first value (the latest date) if there are multiple
 *
 * @param {VulnerabilityCountItem[]} data
 * @returns {VulnerabilityCountResponseItem} Vulnerability metric data ready for rendering in the value stream dashboard
 */
export const extractGraphqlVulnerabilitiesData = (rawVulnerabilityData = []) => {
  const [selectedCount] = rawVulnerabilityData;
  return {
    [VULNERABILITY_METRICS.CRITICAL]: {
      identifier: VULNERABILITY_METRICS.CRITICAL,
      value: selectedCount?.critical || '-',
    },
    [VULNERABILITY_METRICS.HIGH]: {
      identifier: VULNERABILITY_METRICS.HIGH,
      value: selectedCount?.high || '-',
    },
  };
};

const scaledValueForDisplay = (value, units) => {
  if ([UNITS.PERCENT, UNITS.DAYS].includes(units)) {
    return units === UNITS.PERCENT ? formatAsPercentageWithoutSymbol(value) : secondsToDays(value);
  }
  return value;
};

/**
 * @typedef {Object} DoraMetricItem
 * @property {String} date - ISO 8601 date
 * @property {Float} change_failure_rate - Float represention to be converted to percentage
 * @property {Float} deployment_frequency - Per day deployments
 * @property {Float} lead_time_for_changes - Time in seconds
 * @property {Float} time_to_restore_service - Time in seconds
 */

/**
 * @typedef {Object} DoraMetricResponseItem
 * @property {ValueStreamDashboardTableMetric} change_failure_rate - String represention to be converted to percentage
 * @property {ValueStreamDashboardTableMetric} deployment_frequency - Float per day deployments value
 * @property {ValueStreamDashboardTableMetric} lead_time_for_changes - String time in days
 * @property {ValueStreamDashboardTableMetric} time_to_restore_service - String time in days
 */

/**
 * Takes the raw Query.dora graphql response and prepares the data for display
 * in the Value streams dashboard. Assumes that you've used `BUCKETING_INTERVAL_ALL` so
 * there will only be a single data point returned.
 *
 * The DORA endpoint does not include metadata about each of the metrics (label
 * links to docs etc), so we need to mix this data in from the TABLE_METRICS constant
 * to determine the units used to display each metric.
 *
 * @param {DoraMetricItem[]} data
 * @returns {DoraMetricResponseItem} Dora metrics ready for rendering in the value stream dashboard
 */
export const extractGraphqlDoraData = (data = []) => {
  const [bucketedData] = data;
  if (bucketedData && !Object.keys(bucketedData).length) return {};

  return Object.entries(TABLE_METRICS).reduce(
    (acc, [identifier, tmValue]) =>
      bucketedData && bucketedData[identifier]
        ? {
            ...acc,
            [identifier]: {
              identifier,
              value: scaledValueForDisplay(bucketedData[identifier], tmValue.units),
            },
          }
        : acc,
    {},
  );
};

/**
 * @typedef {Object} ValueStreamFlowMetrics
 * @property {String} identifier - Identifier for the specified metric
 * @property {String} title - Display friendly name for the metric
 * @property {String} unit - String name units for the measurement
 * @property {Float} value - Float value for the measurement, scaled ready to be used for display
 * @property {Array} links - Array of links to render for more information
 */

/**
 * @typedef {Object} FlowMetricItem
 * @property {ValueStreamFlowMetrics} cycle_time - ValueStreamFlowMetrics represention to be converted to percentage
 * @property {ValueStreamFlowMetrics} deploys - Per day deployments
 * @property {ValueStreamFlowMetrics} issues - Time in seconds
 * @property {ValueStreamFlowMetrics} lead_time - Time in seconds
 */

/**
 * @typedef {Object} FlowMetricResponseItem
 * @property {ValueStreamDashboardTableMetric} cycle_time - ValueStreamDashboardTableMetric represention to be converted to percentage
 * @property {ValueStreamDashboardTableMetric} deploys - Per day deployments
 * @property {ValueStreamDashboardTableMetric} issues - Time in seconds
 * @property {ValueStreamDashboardTableMetric} lead_time - Time in seconds
 */

/**
 * Takes the raw Query.flowMetrics graphql response and prepares the data for display
 * removing some unnecessary fields and replacing null values with `-`.
 *
 * @param {FlowMetricItem} data
 * @returns {FlowMetricResponseItem} Flow metrics ready for rendering in the value stream dashboard
 */
export const extractGraphqlFlowData = (data = {}) =>
  Object.entries(TABLE_METRICS).reduce(
    (acc, [identifier]) =>
      data && data[identifier]
        ? {
            ...acc,
            [identifier]: {
              identifier,
              value: data[identifier].value ? data[identifier].value : '-',
            },
          }
        : acc,
    {},
  );

/**
 * @typedef {Object} MergeRequestItem
 * @property {Integer} merge_request_throughput - Count of merge requests merged in the given time period
 */

/**
 * @typedef {Object} MergeRequestResponseItem
 * @property {ValueStreamDashboardTableMetric} merge_request_throughput - Count of merge requests merged in the given time period
 */

/**
 * Takes the raw Query.mergeRequests graphql response and prepares the data for display
 * removing some unnecessary fields and replacing null values with `-`.
 *
 * @param {MergeRequestItem} data
 * @returns {MergeRequestResponseItem} Flow metrics ready for rendering in the value stream dashboard
 */
export const extractGraphqlMergeRequestsData = (data = {}) =>
  Object.entries(TABLE_METRICS).reduce(
    (acc, [identifier]) =>
      data && data[identifier]
        ? {
            ...acc,
            [identifier]: {
              identifier,
              value: data[identifier] ? data[identifier] : '-',
            },
          }
        : acc,
    {},
  );

/**
 * Fetches and merges DORA metrics into the given timePeriod objects.
 *
 * @param {Array} timePeriods - array of objects containing DORA metric values
 * @param {String} requestPath - URL path to use for the DORA metric API requests
 * @returns {Array} The original timePeriods array, with DORA metrics included
 */
export const fetchDoraMetrics = async ({ timePeriods, requestPath }) => {
  const promises = timePeriods.map((period) =>
    fetchMetricsData(METRICS_REQUESTS, requestPath, {
      created_after: period.start.toISOString(),
      created_before: period.end.toISOString(),
    }),
  );

  const results = await Promise.all(promises);
  return timePeriods.map((period, index) => ({
    ...period,
    ...extractDoraMetrics(results[index]),
  }));
};

/**
 * Takes an array of timePeriods, a query function to execute and query parameters
 * and will execute the queries, returning an array of data in order.
 *
 * @param {Array} timePeriods - Array of time periods [startdate, enddate] to iterate over and request
 * @param {Date} timePeriods.start - Start date for the request
 * @param {Date} timePeriods.end - End date for the request
 * @param {Function} queryFn - A function that returns a promise to execute a query, eg REST api request, graphql query
 * @param {Object} [queryParameters] - Optional parameters to pass to the query function
 * @returns {Array} Array of data results from each query
 */
export const fetchMetricsForTimePeriods = async (timePeriods, queryFn, queryParameters = {}) => {
  const promises = timePeriods.map(async (timePeriod) => {
    const { start, end } = timePeriod;
    const res = await queryFn(
      {
        startDate: start.toISOString(),
        endDate: end.toISOString(),
        ...queryParameters,
      },
      timePeriod,
    );

    return res;
  });

  return Promise.all(promises);
};

/**
 * Fetches and returns the parsed YAML config file.
 *
 * @param {Number} projectId - ID of the project that contains the YAML config file
 * @returns {Object} The parsed YAML config file
 */
export const fetchYamlConfig = async (projectId) => {
  if (!projectId) return null;

  try {
    const { data } = await Api.getRawFile(projectId, YAML_CONFIG_PATH);
    return parse(data);
  } catch {
    return null;
  }
};

/**
 * @typedef {Object} DoraPerformanceScoreCountItem
 * @property {String} __typename - DoraPerformanceScoreCount
 * @property {String} metricName - Metric identifier
 * @property {Integer} lowProjectsCount - Count of projects that score 'low' on the metric
 * @property {Integer} mediumProjectsCount - Count of projects that score 'medium' on the metric
 * @property {Integer} highProjectsCount - Count of projects that score 'high' on the metric
 * @property {Integer} noDataProjectsCount - Count of projects that have no data
 */

/**
 * Takes the raw Group.doraPerformanceScoreCounts graphql response and prepares the data for display
 * in the tiled column chart.
 *
 * @param {DoraPerformanceScoreCountItem[]} data
 * @returns {Array} DORA performance score counts ready for rendering in the tiled column chart
 */
export const extractDoraPerformanceScoreCounts = (data = []) => {
  const scoreCountsByCategory = groupDoraPerformanceScoreCountsByCategory(data);

  return Object.entries(DORA_PERFORMERS_SCORE_CATEGORIES).map(([category, label]) => ({
    name: label,
    data: scoreCountsByCategory[category] ?? [],
  }));
};
