import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import {
  getMonthNames,
  getDateInPast,
  getDayDifference,
  secondsToDays,
} from '~/lib/utils/datetime_utility';
import {
  THROUGHPUT_CHART_STRINGS,
  DEFAULT_NUMBER_OF_DAYS,
  UNITS,
  EXCLUDED_DATA_KEYS,
} from './constants';

/**
 * A utility function which accepts a date range and returns
 * computed month data which is required to build the GraphQL
 * query for the Throughput Analytics chart
 *
 * @param {Date} startDate the startDate for the data range
 * @param {Date} endDate the endDate for the data range
 * @param {String} format the date format to be used
 *
 * @return {Array} the computed month data
 */
export const computeMonthRangeData = (startDate, endDate, format = dateFormats.isoDate) => {
  const monthData = [];
  const monthNames = getMonthNames(true);

  for (
    let dateCursor = new Date(endDate);
    dateCursor >= startDate;
    dateCursor.setMonth(dateCursor.getMonth(), 0)
  ) {
    const monthIndex = dateCursor.getMonth();
    const year = dateCursor.getFullYear();

    const mergedAfter = new Date(year, monthIndex, 1);
    const mergedBefore = new Date(year, monthIndex + 1, 1);

    monthData.unshift({
      year,
      month: monthNames[monthIndex],
      mergedAfter: dateFormat(mergedAfter, format),
      mergedBefore: dateFormat(mergedBefore, format),
    });
  }

  if (monthData.length) {
    monthData[0].mergedAfter = dateFormat(startDate, format); // Set first item to startDate
    monthData[monthData.length - 1].mergedBefore = dateFormat(endDate, format); // Set last item to endDate
  }

  return monthData;
};

/**
 * A utility function which accepts the raw throughput chart data
 * and transforms it into the format required for the area chart.
 *
 * @param {Object} chartData the raw chart data
 *
 * @return {Array} the formatted chart data
 */
export const formatThroughputChartData = (chartData) => {
  if (!chartData) return [];
  const data = Object.keys(chartData)
    .filter((key) => !EXCLUDED_DATA_KEYS.includes(key.toLowerCase()))
    .map((key) => [key.split('_').join(' '), chartData[key].count]); // key: Aug_2020 => Aug 2020

  return [
    {
      name: THROUGHPUT_CHART_STRINGS.Y_AXIS_TITLE,
      data,
    },
  ];
};

/**
 * A utility function which accepts the raw throughput data
 * and computes the mean time to merge.
 *
 * @param {Object} rawData the raw throughput data
 *
 * @return {Object} the computed MTTM data
 */
export const computeMttmData = (rawData) => {
  if (!rawData) return {};

  const mttmData = Object.values(rawData)
    // eslint-disable-next-line @gitlab/require-i18n-strings
    .filter((value) => value !== 'Project')
    .reduce(
      (total, monthData) => {
        return {
          count: total.count + monthData.count,
          totalTimeToMerge: total.totalTimeToMerge + monthData.totalTimeToMerge,
        };
      },
      {
        count: 0,
        totalTimeToMerge: 0,
      },
    );

  const value =
    mttmData.totalTimeToMerge && mttmData.count
      ? secondsToDays(mttmData.totalTimeToMerge / mttmData.count)
      : '-';
  return {
    title: THROUGHPUT_CHART_STRINGS.MTTM,
    unit: UNITS.DAYS,
    value,
  };
};

/**
 * A utility function which accepts start and end date params
 * and validates that the date range does not exceed the bounds
 *
 * @param {Date} startDate the startDate for the data range
 * @param {Date} endDate the endDate for the data range
 *
 * @return {Object} an object containing the startDate and endDate
 */
export const parseAndValidateDates = (startDateParam, endDateParam) => {
  let startDate = new Date(startDateParam);
  let endDate = new Date(endDateParam);
  const numberOfDays = getDayDifference(startDate, endDate);

  if (!startDateParam.length || numberOfDays > DEFAULT_NUMBER_OF_DAYS || endDate < startDate) {
    startDate = getDateInPast(new Date(), DEFAULT_NUMBER_OF_DAYS);
    endDate = new Date();
  }

  return { startDate, endDate };
};
