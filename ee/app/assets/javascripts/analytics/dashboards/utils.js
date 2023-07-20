import { s__, __ } from '~/locale';
import { isNumeric } from '~/lib/utils/number_utils';
import {
  formatDate,
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nMonthsBefore,
  monthInWords,
  nSecondsBefore,
  nDaysBefore,
} from '~/lib/utils/datetime_utility';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { days, percentHundred } from '~/lib/utils/unit_format';
import {
  TABLE_METRICS,
  UNITS,
  CHART_TOOLTIP_UNITS,
  METRICS_WITH_NO_TREND,
  DORA_PERFORMERS_SCORE_CATEGORY_TYPES,
} from './constants';

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
 * Takes N time periods for a metric and generates the row for the comparison table.
 *
 * @param {String} identifier - ID of the metric to create a table row for.
 * @param {String} label - User friendly name of the metric to show in the table row.
 * @param {String} units - The type of units used for this metric (ex. days, /day, count)
 * @param {Boolean} invertTrendColor - Inverts the color indicator used for metric trends.
 * @param {Array} timePeriods - Array of the metrics for different time periods
 * @param {Object} valueLimit - Object representing the maximum value of a metric, mask that replaces the value if the limit is reached and a description to be used in a tooltip.
 * @returns {Object} The metric data formatted for the comparison table.
 */
const buildMetricComparisonTableRow = ({
  identifier,
  label,
  units,
  invertTrendColor,
  timePeriods,
  valueLimit,
}) => {
  const data = {
    invertTrendColor,
    metric: { identifier, value: label },
    valueLimit,
  };
  timePeriods.forEach((timePeriod, index) => {
    // The last timePeriod is not rendered, we just use it
    // to determine the % change for the 2nd last timePeriod
    if (index === timePeriods.length - 1) return;

    const current = timePeriod[identifier];
    const previous = timePeriods[index + 1][identifier];
    const hasCurrentValue = current && current.value !== '-';
    const hasPreviousValue = previous && previous.value !== '-';
    const change = !METRICS_WITH_NO_TREND.includes(identifier)
      ? percentChange({
          current: hasCurrentValue ? current.value : 0,
          previous: hasPreviousValue ? previous.value : 0,
        })
      : null;
    const valueLimitMessage =
      hasCurrentValue && current.value >= valueLimit?.max ? valueLimit?.description : undefined;
    const formattedMetric = hasCurrentValue ? formatMetric(current.value, units) : '-';
    const value = valueLimitMessage ? valueLimit?.mask : formattedMetric;

    data[timePeriod.key] = {
      value,
      change,
      valueLimitMessage,
    };
  });
  return data;
};

/**
 * Takes N time periods of DORA metrics and generates the data rows
 * for the comparison table.
 *
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @param {Array} excludeMetrics - Array of DORA metric identifiers to remove from the table
 * @returns {Array} array comparing each DORA metric between the different time periods
 */
export const generateDoraTimePeriodComparisonTable = ({ timePeriods, excludeMetrics = [] }) =>
  Object.entries(TABLE_METRICS)
    .filter(([identifier]) => !excludeMetrics.includes(identifier))
    .map(([identifier, { label, units, invertTrendColor, valueLimit }]) =>
      buildMetricComparisonTableRow({
        identifier,
        label,
        units,
        invertTrendColor,
        timePeriods,
        valueLimit,
      }),
    );

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
  return [5, 4, 3, 2, 1, 0].map((monthsAgo, index) => ({
    end: monthsAgo === 0 ? now : nMonthsBefore(now, monthsAgo),
    start: nMonthsBefore(now, monthsAgo + 1),
    key: `chart-period-${index}`,
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

/**
 * For the `DoraMetric` query endpoint, we need to supply YMD dates,
 * but the query will fail if we send the same date twice, this occurs on
 * the first of the month, so in those cases we should continue to show
 * date for the last month.
 *
 * See: https://gitlab.com/gitlab-org/gitlab/-/issues/413872
 * @returns {Date} the start date to use for queries
 */
export const generateValueStreamDashboardStartDate = () => {
  const now = new Date();
  return now.getDate() === 1 ? nDaysBefore(now, 1) : now;
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
 * @typedef {Object} DoraPerformanceScoreCountsByCategory
 * @property {Array} lowProjectsCount - Array of all project counts with 'low' metric scores
 * @property {Array} mediumProjectsCount - Array of all project counts with 'medium' metric scores
 * @property {Array} highProjectsCount - Array of all project counts with 'high' metric scores
 * @property {Array} noDataProjectsCount - Array of all project counts with no data for their respective metric scores
 */

/**
 * Takes an array of DoraPerformanceScoreCount objects and returns a dictionary of
 * DORA performance score categories to an array of count values.
 *
 * For example, given the following array:
 * [
 *     {
 *       __typename: 'DoraPerformanceScoreCount',
 *       metricName: 'deployment_frequency',
 *       lowProjectsCount: 27,
 *       mediumProjectsCount: 24,
 *       highProjectsCount: 86,
 *       noDataProjectsCount: 1,
 *     },
 *     {
 *       __typename: 'DoraPerformanceScoreCount',
 *       metricName: 'lead_time_for_changes',
 *       lowProjectsCount: 25,
 *       mediumProjectsCount: 30,
 *       highProjectsCount: 75,
 *       noDataProjectsCount: 1,
 *     },
 *     ...
 * ]
 *
 * It will return the following object:
 *
 * {
 *   highProjectsCount: [86, 75],
 *   mediumProjectsCount: [24, 30],
 *   lowProjectsCount: [27, 25],
 *   noDataProjectsCount: [1, 1],
 * }
 *
 * @param {DoraPerformanceScoreCountItem[]} data - Array of DoraPerformanceScoreCount objects
 * @returns {DoraPerformanceScoreCountsByCategory} - A dictionary of each DORA performance score category with an array of count values
 */
export const groupDoraPerformanceScoreCountsByCategory = (data = []) => {
  const scoresCountsByCategory = {};
  const scoreCategoryTypes = Object.values(DORA_PERFORMERS_SCORE_CATEGORY_TYPES);

  scoreCategoryTypes.forEach((category) => {
    scoresCountsByCategory[category] = [];
  });

  data.forEach((scoreCount) => {
    scoreCategoryTypes.forEach((category) => {
      const scoreCounts = scoresCountsByCategory[category];

      scoresCountsByCategory[category] = [...scoreCounts, scoreCount[category]];
    });
  });

  return scoresCountsByCategory;
};
