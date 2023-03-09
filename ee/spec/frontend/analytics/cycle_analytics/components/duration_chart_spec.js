import { GlIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import {
  DURATION_STAGE_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_STAGE_TIME_NO_DATA,
  DURATION_TOTAL_TIME_NO_DATA,
} from 'ee/analytics/cycle_analytics/constants';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  allowedStages as stages,
  durationChartPlottableData as durationData,
  durationDataSeries,
  durationDataNullSeries,
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
          durationChartPlottableData: () => durationData,
          ...initialGetters,
        },
        state: {
          isLoading: false,
          ...initialState,
        },
      },
    },
  });

function createComponent({
  stubs = {},
  initialState = {},
  initialGetters = {},
  rootGetters = {},
  rootState = {},
  props = {},
} = {}) {
  return shallowMount(DurationChart, {
    store: fakeStore({ initialState, initialGetters, rootGetters, rootState }),
    propsData: {
      stages,
      ...props,
    },
    stubs: {
      ChartSkeletonLoader: true,
      ...stubs,
    },
  });
}

describe('DurationChart', () => {
  let wrapper;

  const findContainer = (_wrapper) => _wrapper.find('[data-testid="vsa-duration-chart"]');
  const findChartDescription = (_wrapper) => _wrapper.findComponent(GlIcon);
  const findDurationChart = (_wrapper) => _wrapper.findComponent(GlLineChart);
  const findLoader = (_wrapper) => _wrapper.findComponent(ChartSkeletonLoader);

  describe('with the overiew stage selected', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    it('renders the duration chart', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('correctly sets the chart options data property', () => {
      const chartDataProps = findDurationChart(wrapper).props('data');
      const [dataSeries, nullSeries] = chartDataProps;
      const expectedParams = ['areaStyle', 'data', 'itemStyle', 'lineStyle', 'name', 'showSymbol'];

      expectedParams.forEach((param) => {
        expect(dataSeries[param]).toEqual(durationDataSeries[param]);
        expect(nullSeries[param]).toEqual(durationDataNullSeries[param]);
      });
    });

    it('renders the chart', () => {
      expect(findDurationChart(wrapper).exists()).toBe(true);
    });

    it('renders the chart description', () => {
      expect(findChartDescription(wrapper).attributes('title')).toBe(
        DURATION_TOTAL_TIME_DESCRIPTION,
      );
    });

    describe('with no chart data', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialGetters: {
            durationChartPlottableData: () => [],
          },
        });
      });

      it('renders the no data available message', () => {
        expect(findContainer(wrapper).text()).toContain(DURATION_TOTAL_TIME_NO_DATA);
      });
    });
  });

  describe('with a value stream stage selected', () => {
    const [selectedStage] = stages;

    beforeEach(() => {
      wrapper = createComponent({
        rootState: {
          selectedStage,
        },
        rootGetters: {
          isOverviewStageSelected: () => false,
        },
      });
    });

    it('renders the chart', () => {
      expect(findDurationChart(wrapper).exists()).toBe(true);
    });

    it('renders the stage title', () => {
      expect(wrapper.text()).toContain(`Stage time: ${selectedStage.title}`);
    });

    it('sets the chart data', () => {
      expect(findDurationChart(wrapper).props('data')).toEqual([
        expect.objectContaining(durationDataSeries),
        durationDataNullSeries,
      ]);
    });

    it('renders the chart description', () => {
      expect(findChartDescription(wrapper).attributes('title')).toBe(
        DURATION_STAGE_TIME_DESCRIPTION,
      );
    });

    describe('with no chart data', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialGetters: {
            durationChartPlottableData: () => [[new Date(), null]],
          },
          rootState: {
            selectedStage,
          },
          rootGetters: {
            isOverviewStageSelected: () => false,
          },
        });
      });

      it('renders the no data available message', () => {
        expect(findContainer(wrapper).text()).toContain(DURATION_STAGE_TIME_NO_DATA);
      });
    });
  });

  describe('when isLoading=true', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { isLoading: true } });
    });

    it('renders a loader', () => {
      expect(findLoader(wrapper).exists()).toBe(true);
    });
  });
});
