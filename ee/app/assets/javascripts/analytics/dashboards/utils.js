import { isNumeric } from '~/lib/utils/number_utils';
import { roundOffFloat } from '~/lib/utils/common_utils';
import { fetchMetricsData } from '~/analytics/shared/utils';
import { METRICS_REQUESTS } from '~/cycle_analytics/constants';
import { CHANGE_FAILURE_RATE, DEPLOYMENT_FREQUENCY_METRIC_TYPE } from 'ee/api/dora_api';
import { DORA_METRIC_IDENTIFIERS } from './constants';

export const formatPercentChange = ({ current, previous, precision = 2 }) =>
  previous > 0 && current > 0
    ? `${roundOffFloat(((current - previous) / previous) * 100, precision)}%`
    : '-';

export const formatMetricString = ({ identifier, value }) => {
  let unit = '';
  switch (identifier) {
    case CHANGE_FAILURE_RATE:
      unit = '%';
      break;
    case DEPLOYMENT_FREQUENCY_METRIC_TYPE:
      unit = '/d';
      break;
    default:
      unit = ' d';
      break;
  }
  return `${value}${unit}`;
};

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
    .filter(({ identifier }) => DORA_METRIC_IDENTIFIERS.includes(identifier))
    .reduce((acc, curr) => {
      return {
        ...acc,
        [curr.identifier]: curr,
      };
    }, {});

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
 * Takes an array of timePeriod objects containing DORA metrics, and returns
 * true if any of the timePeriods contain metric values > 0.
 *
 * @param {Array} timePeriods - array of objects containing DORA metric values
 * @returns {Boolean} true if there is any metric data, otherwise false.
 */
export const hasDoraMetricValues = (timePeriods) =>
  timePeriods.some((timePeriod) => {
    // timePeriod may contain more attributes than just the DORA metrics,
    // so filter out non-metrics before making a list of the raw values
    const metricValues = Object.entries(timePeriod)
      .filter(([k]) => DORA_METRIC_IDENTIFIERS.includes(k))
      .map(([, v]) => v.value);

    return metricValues.some((value) => isNumeric(value) && Number(value) > 0);
  });

/**
 * Takes N time periods of DORA metrics and generates the data rows
 * for the comparison table.
 *
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @returns {Array} array comparing each DORA metric between the different time periods
 */
export const generateDoraTimePeriodComparisonTable = (timePeriods) => {
  return DORA_METRIC_IDENTIFIERS.map((identifier) => {
    const data = {};
    timePeriods.forEach((timePeriod) => {
      const doraMetric = timePeriod[identifier];
      data.metric = doraMetric.label;
      data[timePeriod.key] = doraMetric?.identifier ? formatMetricString(doraMetric) : '-';
    });
    return data;
  });
};
