import { DATA_VIZ_BLUE_500, GRAY_300, GRAY_50 } from '@gitlab/ui/dist/tokens/js/tokens';
import { defaultAreaOpacity } from '@gitlab/ui/dist/utils/charts/config';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export const scatterChartLineProps = {
  default: {
    type: 'line',
    showSymbol: false,
    // By default zlevel is 2 for all series types.
    // By increasing the zlevel to 3 we make sure that the trendline gets drawn in front of the dots in the chart.
    zlevel: 3,
  },
};

export const DATA_REFETCH_DELAY = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

export const BASE_SERIES_DATA_OPTIONS = {
  showSymbol: true,
  showAllSymbol: true,
  symbolSize: 8,
  lineStyle: {
    color: DATA_VIZ_BLUE_500,
  },
  itemStyle: {
    color: DATA_VIZ_BLUE_500,
  },
};

export const DEFAULT_SERIES_DATA_OPTIONS = {
  ...BASE_SERIES_DATA_OPTIONS,
  areaStyle: {
    opacity: 0,
  },
};

export const BASE_NULL_SERIES_OPTIONS = {
  showSymbol: false,
  lineStyle: {
    type: 'dashed',
    color: GRAY_300,
  },
  itemStyle: {
    color: GRAY_300,
  },
};

export const DEFAULT_NULL_SERIES_OPTIONS = {
  ...BASE_NULL_SERIES_OPTIONS,
  areaStyle: {
    color: 'none',
  },
};

export const BASE_FORECAST_SERIES_OPTIONS = {
  lineStyle: { type: 'dashed', color: DATA_VIZ_BLUE_500 },
  areaStyle: { opacity: defaultAreaOpacity, color: GRAY_50 },
};

export const STACKED_AREA_CHART_SERIES_OPTIONS = {
  stack: 'chart',
};

export const STACKED_AREA_CHART_NULL_SERIES_OPTIONS = {
  stack: 'null',
};
