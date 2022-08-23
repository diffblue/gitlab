import { flatten } from 'lodash';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { getDayDifference, getDateInPast } from '~/lib/utils/datetime_utility';
import { median } from '~/lib/utils/number_utils';

/**
 * Gets the labels endpoint for a given group or project
 * @param {String} namespacePath - The group's namespace.
 * @param {String} projectPathWithNamespace - The project's name including the group's namespace
 * @returns {String} - The labels endpoint path
 */
export const getLabelsEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/labels`;
  }

  return `/groups/${namespacePath}/-/labels`;
};

/**
 * Gets the milestones endpoint for a given group or project
 * @param {String} namespacePath - The group's namespace.
 * @param {String} projectPathWithNamespace - The project's name including the group's namespace
 * @returns {String} - The milestones endpoint path
 */
export const getMilestonesEndpoint = (namespacePath, projectPathWithNamespace) => {
  if (projectPathWithNamespace) {
    return `/${projectPathWithNamespace}/-/milestones`;
  }

  return `/groups/${namespacePath}/-/milestones`;
};

/**
 * Determines the default min date for the productivity analytics date picker
 * by taking the minDate (provided by the BE) into account.
 * @param {Date} minDate - The min start date provided by the backend.
 * @param {Number} defaultDaysInPast - The number of days in the past (used for computing the start date).
 * @returns {Date} - The computed default start date.
 */
export const getDefaultStartDate = (minDate, defaultDaysInPast) => {
  const now = new Date(Date.now());
  const dateInPast = getDateInPast(now, defaultDaysInPast);

  if (!minDate) {
    return dateInPast;
  }

  return minDate > dateInPast ? minDate : dateInPast;
};

/**
 * Computes the day difference 'days' between a given start and end date
 * and creates an array of length 'days'.
 * For each day in the array it initializes an empty array.
 *
 * E.g. initDateArray(new Date('2019-01-01'), new Date('2019-01-03'))
 * the following data structure gets generated: [ [], [], [] ]
 * @param {Date} startDate - The start date
 * @param {Date} endDate - The end date
 */
export const initDateArray = (startDate, endDate) => {
  const days = getDayDifference(startDate, endDate);
  return Array.from({ length: days + 1 }, () => []);
};

/**
 * Transforms the raw scatter data into a data strucuture that allows easy access.
 * It creates a two dimensional array where each item in the first dimension corresponds to one day (date).
 *
 * I.e., the first item corresponds to the start date, the second item corresponds to the start date plus one day,
 * the last item corresponds to the end date.
 *
 * For each date, we store an array of individual MRs for the particular date (i.e, the second dimension) in the following form:
 * { merged_at: '2019-09-01T04:55:05.757Z', metric: 10 }
 *
 * Given that startDate=2019-09-01 and endDate=2019-09-03 we receive the following data structure:
 * [
 *   [{ merged_at: '2019-09-01T04:55:05.757Z', metric: 10 }, { merged_at: '2019-09-01T14:12:09.757Z', metric: 8 }, { ... }] // 2019-09-01
 *   [{ merged_at: '2019-09-02T08:29:33.748Z', metric: 7 }, ... ] // 2019-09-02
 *   [{ merged_at: '2019-09-03T21:29:49.351Z', metric: 24 }, ... ] // 2019-09-03
 * ]
 *
 * @param {Object} data - The raw data received from the API.
 * @param {Date} startDate - The start date selected by the user minus an additional offset in days (e.g., 30 days).
 * @param {Date} endDate - The end date selected by the user.
 * @returns {Array} The transformed data array (first item corresponds to start date, last item to end date)
 */
export const transformScatterData = (data, startDate, endDate) => {
  const result = initDateArray(startDate, endDate);
  const totalItems = result.length;

  Object.keys(data).forEach((id) => {
    const mergedAtDate = new Date(data[id].merged_at);
    const dayDiff = getDayDifference(mergedAtDate, endDate);

    if (dayDiff > -1) {
      const idx = totalItems - (dayDiff + 1);
      // When dealing with different time zones (merged_at is in UTC but endDate is in the browser's timezone)
      // the computed idx might be out of bounds because the result array (and its length) is initialized
      // via initDateArray (which takes only the browser's timezone into account)
      // This would lead to result[idx] being undefined, thus we need a sanity check here
      if (result[idx]) {
        result[idx].push(data[id]);
      }
    }
  });

  return result;
};

/**
 * Brings the data the we receive from transformScatterData into a format that can be passed to the chart.
 * Since transformScatterData contains more data than we actually want to display on the scatterplot
 * (it also contains historical data for median computation), we need to extract only the relevant portion of data.
 * First, this method computes the visibleData based on the number of days between startDate and the endDate.
 * Eventually it flattens the data an returns an array of the following structure:
 * [
 *  ['2019-09-02', 7, '2019-09-02T16:21:29.512Z'],
 *  ['2019-09-03', 10, '2019-09-03T04:55:05.757Z'],
 *  ['2019-09-03', 8, '2019-09-03T12:00:01.432Z'],
 *  ...
 * ]
 *
 * In the data above, each array i represents an MR in the scatterplot with the following data:
 * i[0] = date, displayed on x axis
 * i[1] = metric, displayed on y axis
 * i[2] = datetime, used in the tooltip
 *
 * @param {Array} data - The already transformed scatterplot data (which is computed by transformScatterData)
 * @param {Date} startDate - The start date selected by the user
 * @param {Date} endDate - The end date selected by the user
 * @returns {Array} An array with each item being another arry of two items (date, computed median)
 */
export const getScatterPlotData = (data, startDate, endDate) => {
  if (!data.length) return [];

  const startIndex = data.length - 1 - getDayDifference(startDate, endDate);
  const visibleData = data.slice(startIndex);

  // group by date
  const result = flatten(visibleData).map((item) => [
    dateFormat(item.merged_at, dateFormats.isoDate),
    item.metric,
    item.merged_at,
  ]);

  return result;
};

/**
 * Computes the moving median line data, i.e, it computes the 30 day rolling median for every item displayd on the scatterplot
 * For example the 30 day rolling median for startDate=2019-09-01 and endDate=2019-09-03 is computed as follows:
 * First we get the number of days between start and end date.
 * Then, we make sure to simplify our data by only storing an array of the metric values (without other meta info) every datebundleRenderer.renderToStream
 * Finally, for every day i between start and end date, we compute the median of all the metric values for that given day i
 *
 * Example: Rolling median for m days:
 * Calculate median for day i: median[i - m + 1 ... i]
 *
 * @param {Array} data - The already transformed scatterplot data (which is computed by transformScatterData)
 * @param {Date} startDate - The start date selected by the user
 * @param {Date} endDate - The end date selected by the user
 * @param {Number} daysOffset The number of days that to look up data in the past (e.g. 30 days in the past for 30 day rolling median)
 * @returns {Array} An array with each item being another arry of two items (date, computed median)
 */
export const getMedianLineData = (data, startDate, endDate, daysOffset) => {
  const result = [];
  const dayDiff = getDayDifference(startDate, endDate);
  const transformedData = data.map((arr) => arr.map((x) => x.metric));
  const len = data.length;

  let i = len - dayDiff;
  let medianData;
  let flattenedData;
  let startIndex;
  let d;

  while (i <= len) {
    startIndex = i - daysOffset - 1;
    if (transformedData[startIndex] && transformedData[i - 1]) {
      medianData = transformedData.slice(startIndex, i);
      flattenedData = flatten(medianData);
      if (flattenedData.length) {
        d = getDateInPast(endDate, len - i).toISOString();
        result.push([dateFormat(d, dateFormats.isoDate), median(flattenedData)]);
      }
    }
    i += 1;
  }

  return result;
};
