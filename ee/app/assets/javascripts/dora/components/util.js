import dateFormat from '~/lib/dateformat';
import {
  getDatesInRange,
  nDaysBefore,
  nDaysAfter,
  getStartOfDay,
  humanizeTimeInterval,
  SECONDS_IN_DAY,
} from '~/lib/utils/datetime_utility';
import { median } from '~/lib/utils/number_utils';
import { linearRegression } from 'ee/analytics/shared/utils';
import { buildForecast } from '../graphql/api';

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
export const formatAsPercentageWithoutSymbol = (decimalValue = 0, precision = 1) => {
  const parsed = Number.isNaN(Number(decimalValue)) ? 0 : decimalValue;
  return (parsed * 100).toFixed(precision);
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
  return `${formatAsPercentageWithoutSymbol(decimalValue, precision)}%`;
};

/**
 * @typedef {[Date, Integer]} RawChartDataItem
 */

/**
 * Converts the forecast data into series data using
 * the `apiDataToChartSeries` method. The returned series
 * will also include the final data point from the data series.
 *
 * @param {Object} options
 * @param {Array} options.forecastData The forecasted data in JSON format
 * @param {Integer} options.forecastHorizon The number of days to be forecasted
 * @param {String} options.forecastSeriesLabel The name of the series
 * @param {Date} options.endDate The last day (exclusive) of the graph's date range
 * @param {Array} options.dataSeries The historical data in JSON format
 * @returns {RawChartDataItem[]}
 */
export const forecastDataToSeries = ({
  forecastData,
  forecastHorizon,
  forecastSeriesLabel,
  dataSeries,
  endDate,
}) => {
  const { data } = apiDataToChartSeries(
    forecastData,
    endDate,
    nDaysAfter(endDate, forecastHorizon),
    forecastSeriesLabel,
  )[0];

  // Add the last point from the data series so the chart visually joins together
  return [...dataSeries.slice(-1), ...data];
};

/**
 * @typedef {Object} ForecastDataItem
 * @property {Date} date - YYYY-MM-DD date for the datapoint
 * @property {Number} value - Forecasted value
 */

/**
 * Returns a data forecast for the given time horizon
 * - with `useHoltWintersForecast=true` flag set, an API request will be made to build the forecast
 *   using the Holt winters smoothing model
 * - with `useHoltWintersForecast=false` will calculate a linear regression
 *
 * @param {Object} options An object containing the context needed for the forecast request
 * @param {Boolean} options.useHoltWintersForecast - Toggle between Holt winters and Linear regression
 * @param {String} options.forecastHorizon - Number of days to be returned in the forecast
 * @param {String} options.contextId - Context used to generate the holt winters forecast
 * @param {Array} options.rawApiData - Historical data used for generating the linear regression
 * @returns {ForecastDataItem[]}
 */
export const calculateForecast = ({
  useHoltWintersForecast = false,
  forecastHorizon,
  contextId,
  rawApiData,
}) => {
  return useHoltWintersForecast
    ? buildForecast(contextId, forecastHorizon)
    : linearRegression(rawApiData, forecastHorizon);
};
