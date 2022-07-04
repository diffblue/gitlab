import { dataVizBlue500, gray300 } from '@gitlab/ui/scss_to_js/scss_variables';
import dateFormat from 'dateformat';
import { merge, cloneDeep } from 'lodash';
import {
  getDatesInRange,
  nDaysBefore,
  getStartOfDay,
  humanizeTimeInterval,
  SECONDS_IN_DAY,
} from '~/lib/utils/datetime_utility';
import { median } from '~/lib/utils/number_utils';

/**
 * Converts the raw data fetched from the
 * [DORA Metrics API](https://docs.gitlab.com/ee/api/dora/metrics.html#get-project-level-dora-metrics)
 * into series data consumable by
 * [GlAreaChart](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/charts-area-chart--default)
 *
 * @param {Array} apiData The raw JSON data from the API request
 * @param {Date} startDate The first day (inclusive) of the graph's date range
 * @param {Date} endDate The last day (exclusive) of the graph's date range
 * @param {String} seriesName The name of the series
 * @param {*} emptyValue The value to substitute if the API data doesn't
 * include data for a particular date
 */
export const apiDataToChartSeries = (apiData, startDate, endDate, seriesName, emptyValue = 0) => {
  // Get a list of dates, one date per day in the graph's date range
  const beginningOfStartDate = getStartOfDay(startDate, { utc: true });
  const beginningOfEndDate = nDaysBefore(getStartOfDay(endDate, { utc: true }), 1, { utc: true });
  const dates = getDatesInRange(beginningOfStartDate, beginningOfEndDate).map((d) =>
    getStartOfDay(d, { utc: true }),
  );

  // Generate a map of API timestamps to its associated value.
  // The timestamps are explicitly set to the _beginning_ of the day (in UTC)
  // so that we can confidently compare dates by value below.
  const timestampToApiValue = apiData.reduce((acc, curr) => {
    const apiTimestamp = getStartOfDay(new Date(curr.date), { utc: true }).getTime();
    acc[apiTimestamp] = curr.value;
    return acc;
  }, {});

  // Fill in the API data (the API may exclude data points for dates that have no data)
  // and transform it for use in the graph
  const data = dates.map((date) => {
    const formattedDate = dateFormat(date, 'mmm d', true);
    return [formattedDate, timestampToApiValue[date.getTime()] ?? emptyValue];
  });

  return [
    {
      name: seriesName,
      data,
    },
  ];
};

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
 * @param {Array} seriesData The lead time series data that has already been processed
 * by the `apiDataToChartSeries` function above.
 * @returns {Array} A new series Array
 */
export const buildNullSeries = (seriesData, nullSeriesTitle) => {
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

  merge(nonNullSeries, {
    showSymbol: true,
    showAllSymbol: true,
    symbolSize: 8,
    lineStyle: {
      color: dataVizBlue500,
    },
    areaStyle: {
      color: dataVizBlue500,
      opacity: 0,
    },
    itemStyle: {
      color: dataVizBlue500,
    },
  });

  const nullSeries = {
    name: nullSeriesTitle,
    data: nullSeriesData,
    lineStyle: {
      type: 'dashed',
      color: gray300,
    },
    areaStyle: {
      color: 'none',
    },
    itemStyle: {
      color: gray300,
    },
  };

  return [nullSeries, nonNullSeries];
};

/**
 * Converts a data series into a formatted average series
 *
 * @param {Array} chartSeriesData Correctly formatted chart series data
 *
 * @returns {Object} An object containing the series name and an array of original data keys with the average of the dataset as each value.
 */
export const seriesToAverageSeries = (chartSeriesData, seriesName) => {
  if (!chartSeriesData) return {};

  const average =
    Math.round(
      (chartSeriesData.reduce((acc, day) => acc + day[1], 0) / chartSeriesData.length) * 10,
    ) / 10;

  return {
    name: seriesName,
    data: chartSeriesData.map((day) => [day[0], average]),
  };
};

/**
 * Converts a data series into a formatted median series
 *
 * @param {Array} chartSeriesData Correctly formatted chart series data
 *
 * @returns {Object} An object containing the series name and an array of original data keys with the median of the dataset as each value.
 */
export const seriesToMedianSeries = (chartSeriesData, seriesName) => {
  if (!chartSeriesData) return {};

  const medianValue = median(chartSeriesData.filter((day) => day[1] !== null).map((day) => day[1]));

  return {
    name: seriesName,
    data: chartSeriesData.map((day) => [day[0], medianValue]),
  };
};

/**
 * Converts a time in seconds to number of days, with variable precision
 *
 * @param {Number} seconds Time in seconds
 * @param {Number} precision Specifies the number of digits after the decimal
 *
 * @returns {Float} The number of days
 */
export const secondsToDays = (seconds, precision = 1) =>
  (seconds / SECONDS_IN_DAY).toFixed(precision);

/**
 * Generates the tooltip text and value for time interval series
 *
 * @param {Object} params An object containing a time series and median data
 * @param {String} seriesName The name used to describe the main data series
 * @param {Function} formatter Optional function used to format each value in the data series
 *
 * @returns {Object} Returns an object containing the tooltipTitle and tooltipValue
 */
export const extractTimeSeriesTooltip = (params, seriesName, formatter = humanizeTimeInterval) => {
  let tooltipTitle = null;
  let tooltipValue = null;
  tooltipTitle = params.value;

  const series = params.seriesData[0];

  if (series.data?.length) {
    const seriesValue = series.data[1];
    const trendSeries = params.seriesData[1];

    const { seriesName: trendlineName } = trendSeries;
    const trendSeriesValue = trendSeries.data[1];

    tooltipValue = [
      {
        title: seriesName,
        value: formatter(seriesValue),
      },
      {
        title: trendlineName,
        value: formatter(trendSeriesValue),
      },
    ];
  } else {
    tooltipValue = null;
  }

  return {
    tooltipTitle,
    tooltipValue,
  };
};

/**
 * Formats any valid number as percentage
 *
 * @param {number|string} decimalValue Decimal value between 0 and 1 to be converted to a percentage
 * @param {number} precision The number of decimal places to round to
 *
 * @returns {string} Returns a formatted string multiplied by 100
 */
export const formatAsPercentage = (decimalValue = 0, precision = 1) => {
  const parsed = Number.isNaN(Number(decimalValue)) ? 0 : decimalValue;
  return `${(parsed * 100).toFixed(precision)}%`;
};
