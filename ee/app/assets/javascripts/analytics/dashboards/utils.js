import { roundOffFloat } from '~/lib/utils/common_utils';
import dateformat from '~/lib/dateformat';
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

export const toUtcYMD = (d) => dateformat(d, 'UTC:yyyy-mm-dd');
export const toMonthDay = (d) => dateformat(d, 'mmm dd');

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
 * Takes 2 time periods of DORA metrics and generates the data rows
 * for the comparison table.
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

    const pValue = p ? p.value : '-';
    const cValue = c ? c.value : '-';

    return {
      metric: c.label,
      current: c?.identifier ? formatMetricString(c) : '-',
      previous: p?.identifier ? formatMetricString(p) : '-',
      change: formatPercentChange({ current: cValue, previous: pValue }),
    };
  });
};
