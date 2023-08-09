import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlIcon } from '@gitlab/ui';
import DurationOverviewChart from 'ee/analytics/cycle_analytics/components/duration_overview_chart.vue';
import NoDataAvailableState from 'ee/analytics/cycle_analytics/components/no_data_available_state.vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_OVERVIEW_CHART_NO_DATA_LEGEND_ITEM,
} from 'ee/analytics/cycle_analytics/constants';
import {
  durationOverviewChartPlottableData as mockDurationOverviewChartPlottableData,
  durationOverviewDataSeries,
  durationOverviewDataNullSeries,
  durationOverviewChartOptionsData,
  durationOverviewLegendSeriesInfo,
} from '../mock_data';

Vue.use(Vuex);

const fakeStore = ({ initialGetters, initialState, rootGetters, rootState }) =>
  new Vuex.Store({
    state: {
      ...rootState,
    },
    getters: {
      ...rootGetters,
    },
    modules: {
      durationChart: {
        namespaced: true,
        getters: {
          durationOverviewChartPlottableData: () => mockDurationOverviewChartPlottableData,
          ...initialGetters,
        },
        state: {
          isLoading: false,
          ...initialState,
        },
      },
    },
  });

describe('DurationOverviewChart', () => {
  let wrapper;
  let mockEChartInstance;

  const findChartDescription = () => wrapper.findComponent(GlIcon);
  const findDurationOverviewChart = () => wrapper.findComponent(GlAreaChart);
  const findLoader = () => wrapper.findComponent(ChartSkeletonLoader);
  const findNoDataAvailableState = (_wrapper) => _wrapper.findComponent(NoDataAvailableState);

  const emitChartCreated = () =>
    findDurationOverviewChart().vm.$emit('created', mockEChartInstance);

  const mockChartOptionSeries = [...durationOverviewDataSeries, ...durationOverviewDataNullSeries];

  const createComponent = ({
    stubs = {},
    initialState = {},
    initialGetters = {},
    rootGetters = {},
    rootState = {},
  } = {}) => {
    mockEChartInstance = {
      on: jest.fn(),
      off: jest.fn(),
      getOption: () => {
        return {
          series: mockChartOptionSeries,
        };
      },
    };

    wrapper = shallowMount(DurationOverviewChart, {
      store: fakeStore({ initialState, initialGetters, rootGetters, rootState }),
      stubs: {
        ChartSkeletonLoader: true,
        ...stubs,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent({});
      emitChartCreated();
    });

    it('renders the chart', () => {
      expect(findDurationOverviewChart().exists()).toBe(true);
    });

    it('renders the chart description', () => {
      expect(findChartDescription().attributes('title')).toBe(DURATION_TOTAL_TIME_DESCRIPTION);
    });

    it('correctly sets the chart options data property', () => {
      const chartDataProps = findDurationOverviewChart().props('data');

      expect(chartDataProps).toStrictEqual([
        ...durationOverviewChartOptionsData,
        ...durationOverviewDataNullSeries,
      ]);
    });

    it('correctly sets the chart legend-series-info property', () => {
      const chartLegendSeriesInfoProps = findDurationOverviewChart().props('legendSeriesInfo');

      expect(chartLegendSeriesInfoProps).toStrictEqual([
        ...durationOverviewLegendSeriesInfo,
        DURATION_OVERVIEW_CHART_NO_DATA_LEGEND_ITEM,
      ]);

      expect(chartLegendSeriesInfoProps).toHaveLength(
        mockDurationOverviewChartPlottableData.length + 1,
      );
    });
  });

  describe('with no chart data', () => {
    beforeEach(() => {
      createComponent({
        initialGetters: {
          durationOverviewChartPlottableData: () => [],
        },
      });
    });

    it('renders the no data available message', () => {
      expect(findNoDataAvailableState(wrapper).exists()).toBe(true);
    });
  });

  describe('when isLoading=true', () => {
    beforeEach(() => {
      createComponent({ initialState: { isLoading: true } });
    });

    it('renders a loader', () => {
      expect(findLoader().exists()).toBe(true);
    });
  });
});
