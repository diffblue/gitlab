import { GlDropdownItem, GlIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import {
  DURATION_STAGE_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_STAGE_TIME_NO_DATA,
  DURATION_TOTAL_TIME_NO_DATA,
} from 'ee/analytics/cycle_analytics/constants';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import StageDropdownFilter from 'ee/analytics/cycle_analytics/components/stage_dropdown_filter.vue';
import Scatterplot from 'ee/analytics/shared/components/scatterplot.vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { allowedStages as stages, durationChartPlottableData as durationData } from '../mock_data';

Vue.use(Vuex);

const actionSpies = {
  fetchDurationData: jest.fn(),
  updateSelectedDurationChartStages: jest.fn(),
};

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
        actions: actionSpies,
      },
    },
  });

function createComponent({
  mountFn = shallowMount,
  stubs = {},
  initialState = {},
  initialGetters = {},
  rootGetters = {},
  rootState = {},
  props = {},
} = {}) {
  return mountFn(DurationChart, {
    store: fakeStore({ initialState, initialGetters, rootGetters, rootState }),
    propsData: {
      stages,
      ...props,
    },
    stubs: {
      ChartSkeletonLoader: true,
      Scatterplot: true,
      StageDropdownFilter: true,
      ...stubs,
    },
  });
}

describe('DurationChart', () => {
  let wrapper;

  const findContainer = (_wrapper) => _wrapper.find('[data-testid="vsa-duration-chart"]');
  const findChartDescription = (_wrapper) => _wrapper.findComponent(GlIcon);
  const findScatterPlot = (_wrapper) => _wrapper.findComponent(Scatterplot);
  const findStageDropdown = (_wrapper) => _wrapper.findComponent(StageDropdownFilter);
  const findLoader = (_wrapper) => _wrapper.findComponent(ChartSkeletonLoader);

  const selectStage = (_wrapper, index = 0) => {
    findStageDropdown(_wrapper).findAllComponents(GlDropdownItem).at(index).vm.$emit('click');
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with the overiew stage selected', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    it('renders the duration chart', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the scatter plot', () => {
      expect(findScatterPlot(wrapper).exists()).toBe(true);
    });

    it('renders the stage dropdown', () => {
      expect(findStageDropdown(wrapper).exists()).toBe(true);
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

  describe('when a stage is selected', () => {
    const selectedIndex = 1;
    const selectedStages = stages.filter((_, index) => index !== selectedIndex);
    beforeEach(() => {
      wrapper = createComponent({ stubs: { StageDropdownFilter } });
      selectStage(wrapper, selectedIndex);
    });

    it('calls the `updateSelectedDurationChartStages` action', () => {
      expect(actionSpies.updateSelectedDurationChartStages).toHaveBeenCalledWith(
        expect.any(Object),
        selectedStages,
      );
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

    it('renders the scatter plot', () => {
      expect(findScatterPlot(wrapper).exists()).toBe(true);
    });

    it('does not render the stage dropdown', () => {
      expect(findStageDropdown(wrapper).exists()).toBe(false);
    });

    it('renders the stage title', () => {
      expect(wrapper.text()).toContain(`Stage time: ${selectedStage.title}`);
    });

    it('sets the scatter plot data', () => {
      expect(findScatterPlot(wrapper).props('scatterData')).toBe(durationData);
    });

    it('sets the median line data', () => {
      expect(findScatterPlot(wrapper).props('medianLineData')).toBe(durationData);
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
            durationChartPlottableData: () => [],
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

  describe('with no stages', () => {
    beforeEach(() => {
      wrapper = createComponent({
        mountFn: mount,
        props: { stages: [] },
        stubs: { StageDropdownFilter: false },
      });
    });

    it('does not render the stage dropdown', () => {
      expect(findStageDropdown(wrapper).exists()).toBe(false);
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
