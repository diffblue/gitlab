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
