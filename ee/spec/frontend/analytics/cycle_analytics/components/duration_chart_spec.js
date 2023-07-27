import { GlIcon } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { DURATION_STAGE_TIME_DESCRIPTION } from 'ee/analytics/cycle_analytics/constants';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import NoDataAvailableState from 'ee/analytics/cycle_analytics/components/no_data_available_state.vue';
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

  const findChartDescription = (_wrapper) => _wrapper.findComponent(GlIcon);
  const findDurationChart = (_wrapper) => _wrapper.findComponent(GlLineChart);
  const findLoader = (_wrapper) => _wrapper.findComponent(ChartSkeletonLoader);
  const findNoDataAvailableState = (_wrapper) => _wrapper.findComponent(NoDataAvailableState);

  describe('default', () => {
    const [selectedStage] = stages;

    beforeEach(() => {
      wrapper = createComponent({
        rootState: {
          selectedStage,
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
        });
      });

      it('renders the no data available message', () => {
        expect(findNoDataAvailableState(wrapper).exists()).toBe(true);
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
