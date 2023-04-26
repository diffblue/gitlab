import { s__, __ } from '~/locale';
import { isNumeric } from '~/lib/utils/number_utils';
import {
  formatDate,
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nMonthsBefore,
  monthInWords,
  nSecondsBefore,
} from '~/lib/utils/datetime_utility';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { days, percentHundred } from '~/lib/utils/unit_format';
import { fetchMetricsData } from '~/analytics/shared/utils';
import { METRICS_REQUESTS } from '~/analytics/cycle_analytics/constants';
import { TABLE_METRICS, UNITS, CHART_TOOLTIP_UNITS } from './constants';

/**
 * Checks if a string representation of a value contains an
 * insignificant trailing zero.
 *
 * @param {String} strValue - string representation of the value
 * @returns {Boolean}
 */
export const hasTrailingDecimalZero = (strValue) => /\.\d+[0][^\d]/g.test(strValue);

const patterns = [
  { pattern: '0%', replacement: '%' },
  { pattern: '0/', replacement: '/' },
  { pattern: '0 ', replacement: ' ' },
];

const trimZeros = (value) =>
  patterns.reduce((acc, pattern) => acc.replace(pattern.pattern, pattern.replacement), value);

/**
 * Returns the number of fractional digits that should be shown
 * in the table, based on the value of the given metric.
 *
 * @param {Number} value - the metric value
 * @returns {Number} The number of fractional digits to render
 */
export const fractionDigits = (value) => {
  const absVal = Math.abs(value);
  if (absVal === 0) {
    return 1;
  } else if (absVal < 0.01) {
    return 4;
  } else if (absVal < 0.1) {
    return 3;
  } else if (absVal < 1) {
    return 2;
  }

  return 1;
};

/**
 * Formats the metric value based on the units provided.
 *
 * @param {Number} value - the metric value
 * @param {String} units - PER_DAY, DAYS or PERCENT
 * @returns {String} The formatted metric
 */
export const formatMetric = (value, units) => {
  let formatted = '';
  switch (units) {
    case UNITS.PER_DAY:
      formatted = days(value, fractionDigits(value), { unitSeparator: '/' });
      break;
    case UNITS.DAYS:
      formatted = days(value, fractionDigits(value), { unitSeparator: ' ' });
      break;
    case UNITS.PERCENT:
      formatted = percentHundred(value, fractionDigits(value));
      break;
    default:
      formatted = value;
  }
  return hasTrailingDecimalZero(formatted) ? trimZeros(formatted) : formatted;
};

export const percentChange = ({ current, previous }) =>
  previous > 0 && current > 0 ? (current - previous) / previous : 0;

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
      .filter(([k]) => Object.keys(TABLE_METRICS).includes(k))
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
  const doraMetrics = Object.entries(TABLE_METRICS);
  return doraMetrics.map(([identifier, { label, units, invertTrendColor }]) => {
    const data = { invertTrendColor, metric: { identifier, value: label } };
    timePeriods.forEach((timePeriod, index) => {
      // The last timePeriod is not rendered, we just use it
      // to determine the % change for the 2nd last timePeriod
      if (index === timePeriods.length - 1) return;

      const current = timePeriod[identifier];
      const previous = timePeriods[index + 1][identifier];
      const hasCurrentValue = current && current.value !== '-';
      const hasPreviousValue = previous && previous.value !== '-';

      data[timePeriod.key] = {
        value: hasCurrentValue ? formatMetric(current.value, units) : '-',
        change: percentChange({
          current: hasCurrentValue ? current.value : 0,
          previous: hasPreviousValue ? previous.value : 0,
        }),
      };
    });
    return data;
  });
};

/**
 * @param {Number|'-'|null|undefined} value
 * @returns {Number|null}
 */
const sanitizeSparklineData = (value) => {
  if (!value) return 0;

  // The API returns '-' when it's unable to calculate the metric.
  // By converting the result to null, we prevent the sparkline from
  // rendering a tooltip with the missing data.
  if (value === '-') return null;
  return value;
};

/**
 * Takes N time periods of DORA metrics and sorts the data into an
 * object of timeseries arrays, per metric.
 *
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @returns {Object} object containing a timeseries of values for each metric
 */
export const generateSparklineCharts = (timePeriods) =>
  Object.entries(TABLE_METRICS).reduce(
    (acc, [identifier, { units }]) =>
      Object.assign(acc, {
        [identifier]: {
          tooltipLabel: CHART_TOOLTIP_UNITS[units],
          data: timePeriods.map((timePeriod) => [
            `${formatDate(timePeriod.start, 'mmm d')} - ${formatDate(timePeriod.end, 'mmm d')}`,
            sanitizeSparklineData(timePeriod[identifier]?.value),
          ]),
        },
      }),
    {},
  );

/**
 * Merges the results of `generateDoraTimePeriodComparisonTable` and `generateSparklineCharts`
 * into a new array for the comparison table.
 *
 * @param {Array} tableData - Table rows created by `generateDoraTimePeriodComparisonTable`
 * @param {Object} chartData - Charts object created by `generateSparklineCharts`
 * @returns {Array} A copy of tableData with `chart` added in each row
 */
export const mergeSparklineCharts = (tableData, chartData) =>
  tableData.map((row) => {
    const chart = chartData[row.metric.identifier];
    return chart ? { ...row, chart } : row;
  });

/**
 * Generate the dashboard time periods
 * this month - last month - 2 month ago - 3 month ago
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateDateRanges = (now) => {
  const currentMonthStart = getStartOfDay(dateAtFirstDayOfMonth(now));
  const previousMonthStart = nMonthsBefore(currentMonthStart, 1);
  const previousMonthEnd = nSecondsBefore(currentMonthStart, 1);

  return [
    {
      key: 'thisMonth',
      label: s__('DORA4Metrics|Month to date'),
      start: getStartOfDay(dateAtFirstDayOfMonth(now)),
      end: now,
      thClass: thWidthPercent(20),
    },
    {
      key: 'lastMonth',
      label: monthInWords(nMonthsBefore(now, 1)),
      start: previousMonthStart,
      end: previousMonthEnd,
      thClass: thWidthPercent(20),
    },
    {
      key: 'twoMonthsAgo',
      label: monthInWords(nMonthsBefore(now, 2)),
      start: nMonthsBefore(previousMonthStart, 1),
      end: nSecondsBefore(previousMonthStart, 1),
      thClass: thWidthPercent(20),
    },
    {
      key: 'threeMonthsAgo',
      label: monthInWords(nMonthsBefore(now, 3)),
      start: nMonthsBefore(previousMonthStart, 2),
      end: nSecondsBefore(nMonthsBefore(previousMonthStart, 1), 1),
    },
  ];
};

/**
 * Generate the chart time periods, starting with the oldest first:
 * 5 months ago -> 4 months ago -> etc.
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateChartTimePeriods = (now) => {
  return [5, 4, 3, 2, 1, 0].map((monthsAgo) => ({
    end: monthsAgo === 0 ? now : nMonthsBefore(now, monthsAgo),
    start: nMonthsBefore(now, monthsAgo + 1),
  }));
};

/**
 * Generate the dashboard table fields includes date ranges
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateDashboardTableFields = (now) => {
  return [
    {
      key: 'metric',
      label: __('Metric'),
      thClass: thWidthPercent(25),
    },
    ...generateDateRanges(now).slice(0, -1),
    {
      key: 'chart',
      label: s__('DORA4Metrics|Past 6 Months'),
      start: nMonthsBefore(now, 6),
      end: now,
      thClass: thWidthPercent(15),
      tdClass: 'gl-py-2!',
    },
  ];
};
