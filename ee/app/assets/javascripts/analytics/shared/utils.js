import { merge, cloneDeep, zip } from 'lodash';
import { dateFormats } from '~/analytics/shared/constants';
import { extractVSAFeaturesFromGON } from '~/analytics/shared/utils';
import dateFormat from '~/lib/dateformat';
import {
  convertObjectPropsToCamelCase,
  parseBoolean,
  roundOffFloat,
} from '~/lib/utils/common_utils';
import { getDateInFuture } from '~/lib/utils/datetime/date_calculation_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { fractionDigits } from '../dashboards/utils';
import { DEFAULT_NULL_SERIES_OPTIONS, DEFAULT_SERIES_DATA_OPTIONS } from './constants';

export const formattedDate = (d) => dateFormat(d, dateFormats.defaultDate);

/**
 * Creates a value stream object from a dataset. Returns null if no valueStreamId is present.
 *
 * @param {Object} dataset - The raw value stream object
 * @returns {Object} - A value stream object
 */
export const buildValueStreamFromJson = (valueStream) => {
  const { id, name, is_custom: isCustom } = valueStream ? JSON.parse(valueStream) : {};
  return id ? { id, name, isCustom } : null;
};

/**
 * Creates an array of stage objects from a json string. Returns an empty array if no stages are present.
 *
 * @param {String} stages - JSON encoded array of stages
 * @returns {Array} - An array of stage objects
 */
const buildDefaultStagesFromJSON = (stages = '') => {
  if (!stages.length) return [];
  return JSON.parse(stages);
};

/**
 * Creates a group object from a dataset. Returns null if no groupId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A group object
 */
export const buildGroupFromDataset = (dataset) => {
  const { groupId, groupName, groupFullPath, groupAvatarUrl, groupParentId } = dataset;

  if (groupId) {
    return {
      id: Number(groupId),
      name: groupName,
      full_path: groupFullPath,
      avatar_url: groupAvatarUrl,
      parent_id: groupParentId,
    };
  }

  return null;
};

/**
 * Creates a project object from a dataset. Returns null if no projectId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A project object
 */
export const buildProjectFromDataset = (dataset) => {
  const { projectGid, projectName, projectPathWithNamespace, projectAvatarUrl } = dataset;

  if (projectGid) {
    return {
      id: projectGid,
      name: projectName,
      path_with_namespace: projectPathWithNamespace,
      avatar_url: projectAvatarUrl,
    };
  }

  return null;
};

/**
 * Creates a new date object without time zone conversion.
 *
 * We use this method instead of `new Date(date)`.
 * `new Date(date) will assume that the date string is UTC and it
 * ant return different date depending on the user's time zone.
 *
 * @param {String} date - Date string.
 * @returns {Date} - Date object.
 */
export const toLocalDate = (date) => {
  const dateParts = date.split('-');

  return new Date(dateParts[0], dateParts[1] - 1, dateParts[2]);
};

/**
 * Creates an array of project objects from a json string. Returns null if no projects are present.
 *
 * @param {String} data - JSON encoded array of projects
 * @returns {Array} - An array of project objects
 */
const buildProjectsFromJSON = (projects = '') => {
  if (!projects.length) return [];
  return JSON.parse(projects).map(({ path_with_namespace: fullPath, ...rest }) => ({
    ...rest,
    full_path: fullPath,
  }));
};

/**
 * Builds the initial data object for Value Stream Analytics with data loaded from the backend
 *
 * @param {Object} dataset - dataset object paseed to the frontend via data-* properties
 * @returns {Object} - The initial data to load the app with
 */
export const buildCycleAnalyticsInitialData = ({
  valueStream = null,
  projectId = null,
  groupId = null,
  createdBefore = null,
  createdAfter = null,
  projects = null,
  groupName = null,
  groupPath = null,
  groupFullPath = null,
  groupParentId = null,
  groupAvatarUrl = null,
  labelsPath = '',
  milestonesPath = '',
  defaultStages = null,
  stage = null,
  aggregationEnabled = false,
  aggregationLastRunAt = null,
  aggregationNextRunAt = null,
  namespaceName = null,
  namespaceFullPath = null,
  namespaceType = null,
  enableTasksByTypeChart = false,
  enableCustomizableStages = false,
  enableProjectsFilter = false,
} = {}) => ({
  selectedValueStream: buildValueStreamFromJson(valueStream),
  group: groupId
    ? convertObjectPropsToCamelCase(
        buildGroupFromDataset({
          groupId,
          groupName,
          groupFullPath,
          groupPath,
          groupAvatarUrl,
          groupParentId,
        }),
      )
    : null,
  groupPath: groupPath || groupFullPath,
  createdBefore: createdBefore ? toLocalDate(createdBefore) : null,
  createdAfter: createdAfter ? toLocalDate(createdAfter) : null,
  selectedProjects: projects
    ? buildProjectsFromJSON(projects).map((proj) => ({
        ...convertObjectPropsToCamelCase(proj),
        fullPath: proj.path_with_namespace,
      }))
    : null,
  labelsPath,
  milestonesPath,
  defaultStageConfig: defaultStages
    ? buildDefaultStagesFromJSON(defaultStages).map(({ name, ...rest }) => ({
        ...convertObjectPropsToCamelCase(rest),
        name: capitalizeFirstCharacter(name),
      }))
    : [],
  stage: JSON.parse(stage),
  aggregation: {
    enabled: parseBoolean(aggregationEnabled),
    lastRunAt: aggregationLastRunAt,
    nextRunAt: aggregationNextRunAt,
  },
  features: extractVSAFeaturesFromGON(),
  namespace: {
    name: namespaceName,
    fullPath: namespaceFullPath,
    type: namespaceType,
  },
  enableTasksByTypeChart: parseBoolean(enableTasksByTypeChart),
  enableCustomizableStages: parseBoolean(enableCustomizableStages),
  enableProjectsFilter: parseBoolean(enableProjectsFilter),
  projectId: parseInt(projectId, 10),
});

/**
 * Linearly interpolates between two values
 *
 * @param {Number} valueAtT0 The value at t = 0
 * @param {Number} valueAtT1 The value at t = 1
 * @param {Number} t The current value of t
 *
 * @returns {Number} The result of the linear interpolation.
 */
const lerp = (valueAtT0, valueAtT1, t) => {
  return valueAtT0 * (1 - t) + valueAtT1 * t;
};

/**
 * Builds a second series that visually represents the "no data" (i.e. "null")
 * data points, and returns a new series Array that includes both the "null"
 * and "non-null" data sets.
 * This function returns new series data and does not modify the original instance.
 *
 * @param {object} params - function arguments
 * @param {Array} params.seriesData The time series data that has already been processed
 * by the `apiDataToChartSeries` function.
 * @param {string} params.nullSeriesTitle Sets the title name for the null series
 * @param {object} params.seriesDataOptions Adds additional options for the series data
 * @param {object} params.nullSeriesOptions Adds additional options for the null data
 * @returns {Array} A new series Array
 */
export const buildNullSeries = ({
  seriesData,
  nullSeriesTitle,
  seriesDataOptions = DEFAULT_SERIES_DATA_OPTIONS,
  nullSeriesOptions = DEFAULT_NULL_SERIES_OPTIONS,
}) => {
  const nonNullSeries = cloneDeep(seriesData[0]);
  // Loop through the series data and build a list of all the "gaps". A "gap" is
  // a section of the data set that only include `null` values. Each gap object
  // includes the start and end indices and the start and end values of the gap.
  const seriesGaps = [];
  let currentGap = null;
  nonNullSeries.data.forEach(([, value], index) => {
    if (value == null && currentGap == null) {
      currentGap = {};

      if (index > 0) {
        currentGap.startIndex = index - 1;
        const [, previousValue] = nonNullSeries.data[index - 1];
        currentGap.startValue = previousValue;
      }

      seriesGaps.push(currentGap);
    } else if (value != null && currentGap != null) {
      currentGap.endIndex = index;
      currentGap.endValue = value;
      currentGap = null;
    }
  });

  // Create a copy of the non-null series, but with all the data point values set to `null`
  const nullSeriesData = nonNullSeries.data.map(([date]) => [date, null]);

  // Render each of the gaps to the "null" series. Values are determined by linearly
  // interpolating between the start and end values.
  seriesGaps.forEach((gap) => {
    const startIndex = gap.startIndex ?? 0;
    const startValue = gap.startValue ?? gap.endValue ?? 0;
    const endIndex = gap.endIndex ?? nonNullSeries.data.length - 1;
    const endValue = gap.endValue ?? gap.startValue ?? 0;

    for (let i = startIndex; i <= endIndex; i += 1) {
      const t = (i - startIndex) / (endIndex - startIndex);
      nullSeriesData[i][1] = lerp(startValue, endValue, t);
    }
  });

  merge(nonNullSeries, seriesDataOptions);

  const nullSeries = {
    ...nullSeriesOptions,
    name: nullSeriesTitle,
    data: nullSeriesData,
  };

  return [nullSeries, nonNullSeries];
};

/**
 * Takes an ordered array of axisLabels and 1 or more datasets and creates
 * pairs, each pair consists of the axisLabel and the value from one or more datasets at
 * the current index.
 *
 * datasetName: 'Cool dataset'
 * axisLabels: ['label 1', 'label 2']
 * dataset: [10, 20]
 * returns [{ name: 'Cool dataset', data: [['label 1', 10], ['label 2', 20]]}]
 *
 * @param {object} params - function arguments
 * @param {Array} params.datasetNames - Name parameter for each dataset
 * @param {Array} params.datasets - Array of datasets
 * @param {Array} params.axisLabels - Array of axis labels to be applied to each point in each dataset
 * @returns {Array} Array of objects with the name and paired dataset
 */
export const pairDataAndLabels = ({ datasetNames, datasets = [], axisLabels }) => [
  ...datasets.map((dataset, datasetIndex) => ({
    name: datasetNames[datasetIndex],
    data: zip(axisLabels, dataset.data),
  })),
];

/**
 * Takes average duration in days of a stage on a specific date and returns it with the correct amount digits after the decimal point
 * @param {Number} metric - Average duration in days of a stage on a specific date
 * @returns {number} Formatted metric with correct amount of digits after decimal point
 */
export const formatDurationOverviewTooltipMetric = (metric) => {
  const decimalPlaces = fractionDigits(metric);

  return Number(metric.toFixed(decimalPlaces));
};

/**
 * This function takes a time series of data and computes a
 * slope and intercept to be used for linear regression over the dataset
 *
 * @param {Array} timeSeriesData - The historic time series data which will be used for the linear regression
 * @returns {Object} an object containing the `slope` and `intercept` values
 */
export const calculateSlopeAndInterceptFromDataset = (timeSeriesData) => {
  const x = timeSeriesData.map((element) => new Date(element.date).getTime());
  const y = timeSeriesData.map((element) => element.value);
  const sumX = x.reduce((prev, curr) => prev + curr, 0);
  const avgX = sumX / x.length;
  const xDifferencesToAverage = x.map((value) => avgX - value);
  const xDifferencesToAverageSquared = xDifferencesToAverage.map((value) => value ** 2);
  const SSxx = xDifferencesToAverageSquared.reduce((prev, curr) => prev + curr, 0);
  const sumY = y.reduce((prev, curr) => prev + curr, 0);
  const avgY = sumY / y.length;
  const yDifferencesToAverage = y.map((value) => avgY - value);
  const xAndYDifferencesMultiplied = xDifferencesToAverage.map(
    (curr, index) => curr * yDifferencesToAverage[index],
  );
  const SSxy = xAndYDifferencesMultiplied.reduce((prev, curr) => prev + curr, 0);
  const slope = SSxy / SSxx;
  const intercept = avgY - slope * avgX;

  return {
    slope,
    intercept,
  };
};

/**
 * This function generates a sequential array of dates in the future
 *
 * @param {Date} startDate - the date to start generating from
 * @param {Number} maxDays - the maximum number of days to calculate in the future
 * @returns {Array} an array of dates
 */
export const generateFutureDateRange = (startDate, maxDays) => {
  const futureDates = [];
  for (let i = 1; i <= maxDays; i += 1) {
    futureDates.push(getDateInFuture(startDate, i));
  }
  return futureDates;
};

const calculateRegression = ({ slope, intercept, timeInMilliseconds, rounding }) => {
  return roundOffFloat(intercept + slope * timeInMilliseconds, rounding);
};

/**
 * This function accepts time series data and provides forecasted time series data
 * by applying a least squares linear regression
 *
 * Example input times series data format:
 *
 * [
 *   {"date":"2023-01-12","value":160},
 *   {"date":"2023-01-13","value":52},
 *   {"date":"2023-01-14","value":47},
 *   {"date":"2023-01-15","value":37},
 *   {"date":"2023-01-16","value":106},
 * ]
 *
 *
 * @param {Array} timeSeriesData - The historic time series data which will be used for the linear regression
 * @param {Number} forecastAmount - The number of days which should be forecasted
 * @param {Number} rounding - The number of decimal places to round to
 * @returns {Array} Array of objects with the same time series format, but future dates equal to the forecastAmount value
 */
export const linearRegression = (timeSeriesData, forecastAmount = 30, rounding = 0) => {
  if (!timeSeriesData.length) return [];

  const { slope, intercept } = calculateSlopeAndInterceptFromDataset(timeSeriesData);

  const { date: lastDate } = timeSeriesData[timeSeriesData.length - 1];
  const nextDate = new Date(lastDate);
  const futureDates = generateFutureDateRange(nextDate, forecastAmount);

  return futureDates.map((futureDate) => ({
    date: dateFormat(futureDate, dateFormats.isoDate),
    value: calculateRegression({
      timeInMilliseconds: futureDate.getTime(),
      intercept,
      slope,
      rounding,
    }),
  }));
};
