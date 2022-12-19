import { isEmpty } from 'lodash';
import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { s__ } from '~/locale';
import {
  chartKeys,
  metricTypes,
  columnHighlightStyle,
  scatterPlotAddonQueryDays,
  daysToMergeMetric,
} from '../../../constants';
import { getScatterPlotData, getMedianLineData } from '../../../utils';

export const chartLoading = (state) => (chartKey) => state.charts[chartKey].isLoading;

export const chartErrorCode = (state) => (chartKey) => state.charts[chartKey].errorCode;

/**
 * Creates a series object for the column chart with the given chartKey.
 *
 * Takes an object of the form { "1": 10, "2", 20, "3": 30 } (where the key is the x axis value)
 * and transforms it into into the following structure:
 *
 * {
 *   "full": [
 *     { value: ['1', 10], itemStyle: {} },
 *     { value: ['2', 20], itemStyle: {} },
 *     { value: ['3', 30], itemStyle: {} },
 *   ]
 * }
 *
 * The first item in each value array is the x axis value, the second item is the y axis value.
 * If a value is selected (i.e., set on the state's selected array),
 * the itemStyle will be set accordingly in order to highlight the relevant bar.
 *
 */
export const getColumnChartData = (state) => (chartKey) => {
  const dataWithSelected = Object.keys(state.charts[chartKey].data).map((key) => {
    const dataArr = [key, state.charts[chartKey].data[key]];
    let itemStyle = {};

    if (state.charts[chartKey].selected.indexOf(key) !== -1) {
      itemStyle = columnHighlightStyle;
    }

    return {
      value: dataArr,
      itemStyle,
    };
  });

  return dataWithSelected;
};

export const chartHasData = (state) => (chartKey) => !isEmpty(state.charts[chartKey].data);

export const getScatterPlotMainData = (state, getters, rootState) =>
  getScatterPlotData(
    state.charts.scatterplot.transformedData,
    new Date(rootState.filters.startDate),
    new Date(rootState.filters.endDate),
  );

/**
 * Creates a series array of median data for the scatterplot chart.
 *
 * It calls getMedianLineData internally with the raw scatterplot data and the computed by getters.getScatterPlotMainData.
 * scatterPlotAddonQueryDays is necessary since we query the API with an additional day offset to compute the median.
 */
export const getScatterPlotMedianData = (state, getters, rootState) =>
  getMedianLineData(
    state.charts.scatterplot.transformedData,
    new Date(rootState.filters.startDate),
    new Date(rootState.filters.endDate),
    scatterPlotAddonQueryDays,
  );

export const getMetricLabel = (state) => (chartKey) =>
  metricTypes.find((m) => m.key === state.charts[chartKey].params.metricType).label;

export const getFilterParams = (state, getters, rootState, rootGetters) => (chartKey) => {
  const { params: chartParams = {} } = state.charts[chartKey];

  // common filter params
  const params = {
    ...rootGetters['filters/getCommonFilterParams'](chartKey),
    chart_type: chartParams.chartType,
  };

  // add additional params depending on chart
  if (chartKey !== chartKeys.main) {
    Object.assign(params, { days_to_merge: state.charts.main.selected });

    if (chartParams) {
      Object.assign(params, { metric_type: chartParams.metricType });
    }
  }

  return params;
};

export const getSelectedMetric = (state) => (chartKey) => state.charts[chartKey].params.metricType;

/**
 * Returns the y axis label for the scatterplot.
 * This can either be "Days", "Hours" or some other metric label from the state's metricTypes.
 */
export const scatterplotYaxisLabel = (_state, getters, rootState) => {
  const selectedMetric = getters.getSelectedMetric(chartKeys.scatterplot);
  const metricTypesInHours = rootState.metricTypes
    .filter((metric) => metric.charts.indexOf(chartKeys.timeBasedHistogram) !== -1)
    .map((metric) => metric.key);
  if (selectedMetric === daysToMergeMetric.key) return s__('ProductivityAnalytics|Days');
  if (metricTypesInHours.indexOf(selectedMetric) !== -1) return s__('ProductivityAnalytics|Hours');
  return getters.getMetricLabel(chartKeys.scatterplot);
};

export const hasNoAccessError = (state) =>
  state.charts[chartKeys.main].errorCode === HTTP_STATUS_FORBIDDEN;

export const isChartEnabled = (state) => (chartKey) => state.charts[chartKey].enabled;

export const isFilteringByDaysToMerge = (state) => state.charts[chartKeys.main].selected.length > 0;
