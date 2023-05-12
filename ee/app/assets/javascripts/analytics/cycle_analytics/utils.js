import { uniqBy } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { s__, n__, sprintf } from '~/locale';
import { dateFormats } from '~/analytics/shared/constants';
import { toYmd } from '~/analytics/shared/utils';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import { medianTimeToParsedSeconds } from '~/analytics/cycle_analytics/utils';
import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { newDate, dayAfter, secondsToDays, getDatesInRange } from '~/lib/utils/datetime_utility';
import { isNumeric } from '~/lib/utils/number_utils';
import {
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

const EVENT_TYPE_LABEL = 'label';

export const toggleSelectedLabel = ({ selectedLabels = [], value = null }) => {
  if (!value?.title) return selectedLabels;
  return selectedLabels.find((v) => v.title === value.title)
    ? selectedLabels.filter((v) => v.title !== value.title)
    : [...selectedLabels, value];
};

export const isStartEvent = (ev) =>
  Boolean(ev) && Boolean(ev.canBeStartEvent) && ev.canBeStartEvent;

export const eventToOption = (obj = null) => {
  if (!obj || (!obj.text && !obj.identifier)) return null;
  const { name: text = '', identifier: value = null } = obj;
  return { text, value };
};

export const getAllowedEndEvents = (events = [], targetIdentifier = null) => {
  if (!targetIdentifier || !events.length) return [];
  const st = events.find(({ identifier }) => identifier === targetIdentifier);
  return st && st.allowedEndEvents ? st.allowedEndEvents : [];
};

export const eventsByIdentifier = (events = [], targetIdentifier = []) => {
  if (!targetIdentifier || !targetIdentifier.length || !events.length) return [];
  return events.filter(({ identifier = '' }) => targetIdentifier.includes(identifier));
};

export const isLabelEvent = (labelEvents = [], ev = null) =>
  Boolean(ev) && labelEvents.length && labelEvents.includes(ev);

export const getLabelEventsIdentifiers = (events = []) =>
  events.filter((ev) => ev.type && ev.type === EVENT_TYPE_LABEL).map((i) => i.identifier);

export const transformRawStages = (stages = []) =>
  stages.map(({ id, title, name = '', custom = false, ...rest }) => ({
    ...convertObjectPropsToCamelCase(rest, { deep: true }),
    id,
    title,
    custom,
    name: name.length ? name : title,
  }));

export const transformRawTasksByTypeData = (data = []) => {
  if (!data.length) return [];
  return data.map((d) => convertObjectPropsToCamelCase(d, { deep: true }));
};

/**
 * Prepares the stage errors for use in the create value stream form
 *
 * The JSON error response returns a key value pair, the key corresponds to the
 * index of the stage with errors and the value is the returned error(s)
 *
 * @param {Array} stages - Array of value stream stages
 * @param {Object} errors - Key value pair of stage errors
 * @returns {Array} Returns and array of stage error objects
 */
export const prepareStageErrors = (stages, errors) =>
  stages.length ? stages.map((_, index) => convertObjectPropsToCamelCase(errors[index]) || {}) : [];

/**
 * Takes the duration data for selected stages, transforms the date values and returns
 * the data in a flattened array
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    id: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'average_duration_in_seconds': 1234,
 *        'date': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then transformed and flattened into the following format;
 * [
 *  {
 *    'average_duration_in_seconds': 1234,
 *    'date': '2019-09-02'
 *  },
 *  ...
 * ]
 *
 * @param {Array} data - The duration data for selected stages
 * @returns {Array} An array with each item being an object containing the average_duration_in_seconds and date values for an event
 */
export const flattenDurationChartData = (data) =>
  data
    .map((stage) =>
      stage.data.map((event) => {
        const date = new Date(event.date);
        return {
          ...event,
          date: dateFormat(date, dateFormats.isoDate),
        };
      }),
    )
    .flat();

/**
 * Takes the flat array of average durations and will return a map of
 * dates to an array of all the averages for that date.
 *
 * For example, with the array:
 * [
 *  { average_duration_in_seconds: 1111, date: '2019-09-02'},
 *  { average_duration_in_seconds: 2222, date: '2019-09-01'},
 *  { average_duration_in_seconds: 3333, date: '2019-09-01'},
 * ]
 *
 * Will return the map:
 * Map({
 *  '2019-09-01' => [2222, 3333],
 *  '2019-09-02' => [1111]
 * })
 *
 * @param {Array} flattenedData - A flattened array of objects containing average duration in seconds and the date measured
 * @returns a map of each date with an array of duration values
 */
export const groupDurationsByDay = (flattenedData = []) => {
  const durationMap = new Map();
  return flattenedData.reduce((acc, { date, average_duration_in_seconds: duration }) => {
    const durationArr = acc.has(date) ? [...acc.get(date), duration] : [duration];
    return acc.set(date, durationArr);
  }, durationMap);
};

/**
 * Takes the duration data for selected stages, groups the data by day and calculates the average duration
 * per day, for stages with values on that specific day.
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    id: 'issue',
 *    selected: true,
 *    data: [
 *      {
 *        'average_duration_in_seconds': 1234,
 *        'date': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then computed and transformed into a format that can be passed to the chart:
 * [
 *  ['2019-09-02', 7],
 *  ['2019-09-03', 10],
 *  ['2019-09-04', 8],
 *  ...
 * ]
 *
 * In the data above, each array i represents a point in the scatterplot with the following data:
 * i[0] = date, displayed on x axis
 * i[1] = metric, displayed on y axis
 *
 * @param {Array} data - The duration data for selected stages
 * @param {Date} startDate - The globally selected Value Stream Analytics start date
 * @param {Date} endDate - The globally selected Value Stream Analytics end date
 * @returns {Array} An array with each item being another array of three items (plottable date, computed average)
 */
export const getDurationChartData = (data, startDate, endDate) => {
  const grouped = groupDurationsByDay(flattenDurationChartData(data));

  const eventData = [];
  const endOfDay = newDate(endDate);
  endOfDay.setHours(23, 59, 59); // make sure we're at the end of the day

  for (
    let currentDate = newDate(startDate);
    currentDate <= endOfDay;
    currentDate = dayAfter(currentDate)
  ) {
    const currentISODate = dateFormat(newDate(currentDate), dateFormats.isoDate);
    const valuesForDay = grouped.has(currentISODate)
      ? grouped.get(currentISODate).filter((durationInSeconds) => isNumeric(durationInSeconds))
      : [];

    if (!valuesForDay.length) {
      eventData.push([currentISODate, null]);
    } else {
      const averagedData =
        valuesForDay.reduce((total, value) => total + value, 0) / valuesForDay.length;
      const averagedDataInDays = secondsToDays(averagedData);
      eventData.push([currentISODate, averagedDataInDays]);
    }
  }

  return eventData;
};

/**
 * Takes the duration data of a stage and references a Map of grouped data by date to determine whether to render a null series if a day does not have any data across all stages, or flatten the stage line if a stage does not have data on a specific day but other stages do.
 *
 * For example, given the following duration data:
 * [
 *  { average_duration_in_seconds: null, date: '2023-04-01'},
 *  { average_duration_in_seconds: 259200, date: '2023-04-02'},
 *  { average_duration_in_seconds: null, date: '2023-04-03'},
 * ]
 *
 * And the following Map:
 * Map({
 *  '2023-04-01' => [null, null, null],
 *  '2023-04-02' => [86400, 259200, null],
 *  '2023-04-03' => [432000, 172800, null],
 * })
 *
 * It will return the following array:
 * [
 *  ['2023-04-01', null],
 *  ['2023-04-02', 3],
 *  ['2023-04-03', 0],
 * ]
 *
 * @param {Array} data - Array of objects with average duration in seconds and date
 * @param {Map} groupedDataByDay - a map of dates from all stages with an array of duration values
 * @returns {Array} - Array of arrays with dates and average duration in seconds converted to days
 */
export const formatDurationOverviewChartData = (data, groupedDataByDay) => {
  return data.map(({ average_duration_in_seconds: value, date }) => {
    const currentISODate = dateFormat(new Date(date), dateFormats.isoDate);

    const valuesByDay = groupedDataByDay.has(currentISODate)
      ? groupedDataByDay.get(currentISODate)
      : [];

    if (!valuesByDay.length) return [currentISODate, null];

    const isNonNullSeries = valuesByDay.some((durationData) => isNumeric(durationData));

    if (!isNumeric(value)) {
      return [currentISODate, isNonNullSeries ? 0 : null];
    }

    return [currentISODate, secondsToDays(value)];
  });
};

/**
 * Takes the duration data for selected stages, groups them by day and either flattens the stage line on a specific day depending on the data across stages on that day, renders a null series or returns value to be plotted.
 *
 * The received data is expected to be the following format; One top level object in the array per stage,
 * each potentially having multiple data entries.
 * [
 *   {
 *    id: 'issue',
 *    name: 'Issue',
 *    selected: true,
 *    data: [
 *      {
 *        'average_duration_in_seconds': 1234,
 *        'date': '2019-09-02T18:25:43.511Z'
 *      },
 *      ...
 *    ]
 *   },
 *   ...
 * ]
 *
 * The data is then computed and transformed into a format that can be passed to the chart:
 * [
 *  {
 *    name: 'Issue',
 *    data: [
 *      ['2019-09-02', 7],
 *      ['2019-09-03', 10],
 *      ['2019-09-04', 8],
 *    ]
 *  }
 *  ...
 * ]
 *
 * In the data above, each array i in the data array represents a point in the area chart with the following data:
 * i[0] = date, displayed on x axis
 * i[1] = metric, displayed on y axis
 *
 * @param {Array} data - The duration data for selected stages
 * @returns {Array} An array of stage objects with their names and arrays containing their duration data
 */
export const getDurationOverviewChartData = (data) => {
  const groupedDurationsByDay = groupDurationsByDay(flattenDurationChartData(data));

  return data.map(({ name, data: chartData }) => ({
    name,
    data: formatDurationOverviewChartData(chartData, groupedDurationsByDay),
  }));
};

export const orderByDate = (a, b, dateFmt = (datetime) => new Date(datetime).getTime()) =>
  dateFmt(a) - dateFmt(b);

/**
 * Takes a dictionary of dates and the associated value, sorts them and returns just the value
 *
 * @param {Object.<Date, number>} series - Key value pair of dates and the value for that date
 * @returns {number[]} The values of each key value pair
 */
export const flattenTaskByTypeSeries = (series = {}) =>
  Object.entries(series)
    .sort((a, b) => orderByDate(a[0], b[0]))
    .map((dataSet) => dataSet[1]);

/**
 * @typedef {Object} RawTasksByTypeData
 * @property {Object} label - Raw data for a group label
 * @property {Array} series - Array of arrays with date and associated value ie [ ['2020-01-01', 10],['2020-01-02', 10] ]

 * @typedef {Object} TransformedTasksByTypeData
 * @property {Array} groupBy - The list of dates for the range of data in each data series
 * @property {Array} data - An array of the data values for each series
 * @property {Array} seriesNames - Names of the series to be charted ie label names
 */

/**
 * Takes the raw tasks by type data and generates an array of data points,
 * an array of data series and an array of data labels for the given time period.
 *
 * Currently the data is transformed to support use in a stacked column chart:
 * https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/charts-stacked-column-chart--stacked
 *
 * @param {Object} obj
 * @param {RawTasksByTypeData[]} obj.data - array of raw data, each element contains a label and series
 * @param {Date} obj.createdAfter - start date in ISO date format
 * @param {Date} obj.createdBefore - end date in ISO date format
 *
 * @returns {TransformedTasksByTypeData} The transformed data ready for use in charts
 */
export const getTasksByTypeData = ({ data = [], createdAfter = null, createdBefore = null }) => {
  if (!createdAfter || !createdBefore || !data.length) {
    return {
      groupBy: [],
      data: [],
    };
  }

  const groupBy = getDatesInRange(createdAfter, createdBefore, toYmd).sort(orderByDate);
  const zeroValuesForEachDataPoint = groupBy.reduce(
    (acc, date) => ({
      ...acc,
      [date]: 0,
    }),
    {},
  );

  const transformed = data.reduce(
    (acc, curr) => {
      const {
        label: { title: name },
        series,
      } = curr;
      acc.data = [
        ...acc.data,
        {
          name,
          // adds 0 values for each data point and overrides with data from the series
          data: flattenTaskByTypeSeries({
            ...zeroValuesForEachDataPoint,
            ...Object.fromEntries(series),
          }),
        },
      ];
      return acc;
    },
    {
      data: [],
      seriesNames: [],
    },
  );

  return {
    ...transformed,
    groupBy,
  };
};

const buildDataError = ({ status = HTTP_STATUS_INTERNAL_SERVER_ERROR, error }) => {
  const err = new Error(error);
  err.errorCode = status;
  return err;
};

/**
 * Flashes an error message if the status code is not 200
 *
 * @param {Object} arg
 * @param {Object} arg.error - Axios error object
 * @param {String} arg.message - Error message to display
 */
export const alertErrorIfStatusNotOk = ({ error, message }) => {
  if (error?.errorCode !== HTTP_STATUS_OK) {
    createAlert({
      message,
    });
  }
};

/**
 * Data errors can occur when DB queries for analytics data time out
 * The server will respond with a status `200` success and include the
 * relevant error in the response body
 *
 * @param {Object} Response - Axios ajax response
 * @returns {Object} Returns the axios ajax response
 */
export const checkForDataError = (response) => {
  const { data, status } = response;
  if (data?.error) {
    throw buildDataError({ status, error: data.error });
  }
  return response;
};

export const throwIfUserForbidden = (error) => {
  if (error?.response?.status === HTTP_STATUS_FORBIDDEN) {
    throw error;
  }
};

/**
 * Takes the raw median value arrays and converts them into a useful object
 * containing the string for display in the path navigation, additionally
 * the overview is calculated as a sum of all the stages.
 * ie. converts [{ id: 'test', value: 172800 }] => { 'test': '2d' }
 *
 * @param {Array} Medians - Array of stage median objects, each contains a `id`, `value` and `error`
 * @returns {Object} Returns key value pair with the stage name and its display median value
 */
export const formatMedianValuesWithOverview = (medians = []) => {
  const calculatedMedians = medians.reduce(
    (acc, { id, value = 0 }) => {
      return {
        ...acc,
        [id]: value ? medianTimeToParsedSeconds(value) : '-',
        [OVERVIEW_STAGE_ID]: acc[OVERVIEW_STAGE_ID] + value,
      };
    },
    {
      [OVERVIEW_STAGE_ID]: 0,
    },
  );
  const overviewMedian = calculatedMedians[OVERVIEW_STAGE_ID];
  return {
    ...calculatedMedians,
    [OVERVIEW_STAGE_ID]: overviewMedian ? medianTimeToParsedSeconds(overviewMedian) : '-',
  };
};

/**
 * Takes an array of objects with potential duplicates and returns the deduplicated array
 *
 * @param {Array} arr - The array of objects with potential duplicates
 * @returns {Array} The unique objects from the original array
 */
export const uniqById = (arr = []) => uniqBy(arr, ({ id }) => id);

const selectedLabelsText = (selectedLabelsCount) => {
  return sprintf(
    n__('%{selectedLabelsCount} label', '%{selectedLabelsCount} labels', selectedLabelsCount),
    { selectedLabelsCount },
  );
};

const selectedProjectsText = (selectedProjectsCount) => {
  return sprintf(
    n__(
      '%{selectedProjectsCount} project',
      '%{selectedProjectsCount} projects',
      selectedProjectsCount,
    ),
    { selectedProjectsCount },
  );
};

/**
 * Calculates the tooltip text for the Task by type tooltip,
 * ensuring we correctly externalize the final string for translation.
 *
 * @param  {Object} filters
 * @param  {String} filters.groupName name of the group
 * @param  {String} filters.selectedSubjectFilterText type of subject to filter by (Merge requests | Issues)
 * @param  {Number} filters.selectedProjectsCount number of selected projects
 * @param  {Number} filters.selectedLabelsCount number of selected labels
 * @param  {Date} filters.createdAfter start date to filter by
 * @param  {Date} filters.createdBefore end date to filter by
 * @returns {String} a text description of the currently selected filters
 */
export const generateFilterTextDescription = ({
  selectedProjectsCount,
  selectedLabelsCount,
  selectedSubjectFilterText,
  createdAfter,
  createdBefore,
  groupName,
}) => {
  let str = '';

  const labelsCount = selectedLabelsCount ? selectedLabelsText(selectedLabelsCount) : '';
  const projectsCount = selectedProjectsCount ? selectedProjectsText(selectedProjectsCount) : '';

  if (selectedProjectsCount > 0 && selectedLabelsCount > 0) {
    str = s__(
      "ValueStreamAnalytics|Shows %{selectedSubjectFilterText} and %{labelsCount} for group '%{groupName}' and %{projectsCount} from %{createdAfter} to %{createdBefore}",
    );
  } else if (selectedProjectsCount > 0 && selectedLabelsCount < 1) {
    str = s__(
      "ValueStreamAnalytics|Shows %{selectedSubjectFilterText} for group '%{groupName}' and %{projectsCount} from %{createdAfter} to %{createdBefore}",
    );
  } else if (selectedProjectsCount < 1 && selectedLabelsCount > 0) {
    str = s__(
      "ValueStreamAnalytics|Shows %{selectedSubjectFilterText} and %{labelsCount} for group '%{groupName}' from %{createdAfter} to %{createdBefore}",
    );
  } else {
    str = s__(
      "ValueStreamAnalytics|Shows %{selectedSubjectFilterText} for group '%{groupName}' from %{createdAfter} to %{createdBefore}",
    );
  }
  return sprintf(str, {
    labelsCount,
    projectsCount,
    selectedSubjectFilterText,
    createdAfter,
    createdBefore,
    groupName,
  });
};
