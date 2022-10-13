import { roundOffFloat } from '~/lib/utils/common_utils';
import dateformat from '~/lib/dateformat';
import { DEPLOYMENT_FREQUENCY_METRIC_TYPE, CHANGE_FAILURE_RATE } from 'ee/api/dora_api';
import { DORA_METRIC_IDENTIFIERS } from './constants';

export const formatPercentChange = ({ current, previous, precision = 2 }) =>
  previous > 0 && current > 0
    ? `${roundOffFloat(((current - previous) / previous) * 100, precision)}%`
    : '-';

export const formatMetricString = ({ identifier, value, unit }) =>
  [DEPLOYMENT_FREQUENCY_METRIC_TYPE, CHANGE_FAILURE_RATE].includes(identifier)
    ? `${value}${unit}`
    : `${value} ${unit}`;

export const toUtcYmd = (d) => dateformat(d, 'UTC:yyyy-mm-dd');

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
      const { identifier, ...rest } = curr;
      return {
        ...acc,
        [identifier]: {
          ...rest,
          identifier,
        },
      };
    }, {});

/**
 *
 * @param {Object} obj
 * @param {Array} obj.current - DORA metrics data for the current time period
 * @param {Array} obj.previous - DORA metrics data for the previous time period
 * @returns {Array} array comparing each DORA metric between the 2 time periods
 */
export const generateDoraTimePeriodComparisonTable = ({ current, previous }) => {
  return DORA_METRIC_IDENTIFIERS.map((identifier) => {
    const c = current[identifier];
    const p = previous[identifier];
    return {
      metric: c.label,
      current: formatMetricString(c),
      previous: formatMetricString(p),
      change: formatPercentChange({ current: c.value, previous: p.value }),
    };
  });
};
