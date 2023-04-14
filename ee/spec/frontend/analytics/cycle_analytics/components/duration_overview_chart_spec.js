import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlIcon } from '@gitlab/ui';
import DurationOverviewChart from 'ee/analytics/cycle_analytics/components/duration_overview_chart.vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_NO_DATA,
  DURATION_OVERVIEW_CHART_NO_DATA,
} from 'ee/analytics/cycle_analytics/constants';
import {
  durationOverviewChartPlottableData as durationOverviewData,
  durationOverviewDataSeries,
  durationOverviewDataNullSeries,
  summedDurationOverviewData,
} from '../mock_data';

Vue.use(Vuex);

const fakeStore = ({ initialGetters, initialState, rootGetters, rootState }) =>
  new Vuex.Store({
    state: {
      ...rootState,
    },
    getters: {
      isOverviewStageSelected: () => true,
      ...rootGetters,
    },
    modules: {
      durationChart: {
        namespaced: true,
        getters: {
          durationChartPlottableData: () => durationOverviewData,
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

  const findContainer = () => wrapper.find('[data-testid="vsa-duration-overview-chart"]');
  const findChartDescription = () => wrapper.findComponent(GlIcon);
  const findDurationOverviewChart = () => wrapper.findComponent(GlAreaChart);
  const findLoader = () => wrapper.findComponent(ChartSkeletonLoader);

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
        ...summedDurationOverviewData,
        ...durationOverviewDataNullSeries,
      ]);
    });

    it('correctly sets the chart legend-series-info property', () => {
      const chartLegendSeriesInfoProps = findDurationOverviewChart().props('legendSeriesInfo');

      const getNonNullSeriesInfo = ({ name }) => name !== DURATION_OVERVIEW_CHART_NO_DATA;

      const legendSeriesInfo = mockChartOptionSeries.map(
        ({ name, lineStyle: { color, type } }) => ({
          name,
          color,
          type,
        }),
      );

      const legendNonNullSeriesInfo = legendSeriesInfo.filter(getNonNullSeriesInfo);

      const [nullSeriesItem] = legendSeriesInfo.filter(
        (seriesItem) => !getNonNullSeriesInfo(seriesItem),
      );

      expect(chartLegendSeriesInfoProps).toStrictEqual([
        ...legendNonNullSeriesInfo,
        nullSeriesItem,
      ]);

      expect(chartLegendSeriesInfoProps).toHaveLength(summedDurationOverviewData.length + 1);
    });
  });

  describe('with no chart data', () => {
    beforeEach(() => {
      createComponent({
        initialGetters: {
          durationChartPlottableData: () => [],
        },
      });
    });

    it('renders the no data available message', () => {
      expect(findContainer().text()).toContain(DURATION_TOTAL_TIME_NO_DATA);
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
