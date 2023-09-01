import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import IssuesAnalyticsChart from 'ee/issues_analytics/components/issues_analytics_chart.vue';
import IssuesAnalyticsEmptyState from 'ee/issues_analytics/components/issues_analytics_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createStore } from 'ee/issues_analytics/stores';
import { TEST_HOST } from 'helpers/test_constants';

Vue.use(Vuex);

describe('IssuesAnalyticsChart', () => {
  let wrapper;
  let store;
  let axiosMock;
  let mockDispatch;
  const mockChartData = { '2017-11': 0, '2017-12': 2 };
  const mockChartEmptyData = { '2017-11': 0, '2017-12': 0 };
  const mockBarsData = [
    {
      name: 'Issues created',
      data: [
        ['Nov 2017', 0],
        ['Dec 2017', 2],
      ],
    },
  ];
  const mockFilters = { foo: 'bar' };
  const defaultProvide = {
    endpoint: TEST_HOST,
    filterBlockEl: document.querySelector('#mock-filter'),
    noDataEmptyStateSvgPath: 'svg',
    filtersEmptyStateSvgPath: 'svg',
  };

  const createComponent = async ({
    provide = defaultProvide,
    loading = false,
    chartData = mockChartData,
    filters = {},
  } = {}) => {
    axiosMock = new MockAdapter(axios);
    store = createStore();
    mockDispatch = jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(IssuesAnalyticsChart, {
      provide,
      store,
    });

    store.state.issueAnalytics = {
      loading,
      chartData,
      filters,
    };

    await nextTick();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findChartContainer = () => wrapper.findByTestId('issues-analytics-chart-container');
  const findEmptyState = () => wrapper.findComponent(IssuesAnalyticsEmptyState);
  const findColumnChart = () => wrapper.findComponent(GlColumnChart);

  afterEach(() => {
    axiosMock.restore();
  });

  it('fetches chart data when mounted', async () => {
    await createComponent();

    expect(mockDispatch).toHaveBeenCalledWith('issueAnalytics/fetchChartData', TEST_HOST);
  });

  it('fetches data when filters are applied', async () => {
    await createComponent({ filters: mockFilters });

    expect(mockDispatch).toHaveBeenCalledTimes(2);
    expect(mockDispatch.mock.calls[1]).toEqual(['issueAnalytics/fetchChartData', TEST_HOST]);
  });

  describe('when there is data', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders chart', () => {
      expect(findChartContainer().exists()).toBe(true);
    });

    it('correctly sets the chart `bars` prop', () => {
      expect(findColumnChart().props('bars')).toEqual(mockBarsData);
    });
  });

  it('renders loading state when loading', async () => {
    await createComponent({ loading: true });

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findChartContainer().exists()).toBe(false);
  });

  describe('when chart data is empty', () => {
    describe('and filters have not been applied', () => {
      beforeEach(async () => {
        await createComponent({ chartData: mockChartEmptyData });
      });

      it('should render "no data" empty state', () => {
        expect(findEmptyState().props('emptyStateType')).toBe('noData');
        expect(findChartContainer().exists()).toBe(false);
      });

      it('emits "hasNoData" event', () => {
        expect(wrapper.emitted('hasNoData')).toBeDefined();
      });
    });

    describe('and filters have been applied', () => {
      beforeEach(async () => {
        await createComponent({ chartData: mockChartEmptyData, filters: mockFilters });
      });

      it('should render "filters" empty state', () => {
        expect(findEmptyState().props('emptyStateType')).toBe('noDataWithFilters');
        expect(findChartContainer().exists()).toBe(false);
      });

      it('does not emit "hasNoData" event', () => {
        expect(wrapper.emitted('hasNoData')).toBeUndefined();
      });
    });
  });
});
