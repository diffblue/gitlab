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
  const mockBarsData = [
    {
      name: 'Issues created',
      data: [
        ['Nov 2017', 0],
        ['Dec 2017', 2],
      ],
    },
  ];
  const defaultProvide = {
    endpoint: TEST_HOST,
    filterBlockEl: document.querySelector('#mock-filter'),
    noDataEmptyStateSvgPath: 'svg',
    filtersEmptyStateSvgPath: 'svg',
  };

  const createComponent = ({ provide = defaultProvide } = {}) => {
    axiosMock = new MockAdapter(axios);
    store = createStore();
    mockDispatch = jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMountExtended(IssuesAnalyticsChart, {
      provide,
      store,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findChartContainer = () => wrapper.findByTestId('issues-analytics-chart-container');
  const findEmptyState = () => wrapper.findComponent(IssuesAnalyticsEmptyState);
  const findColumnChart = () => wrapper.findComponent(GlColumnChart);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('fetches chart data when mounted', () => {
    expect(mockDispatch).toHaveBeenCalledWith('issueAnalytics/fetchChartData', TEST_HOST);
  });

  it('renders chart when data is present', async () => {
    store.state.issueAnalytics.chartData = mockChartData;

    await nextTick();

    expect(findChartContainer().exists()).toBe(true);
  });

  it('correctly sets the chart `bars` prop', async () => {
    store.state.issueAnalytics.chartData = mockChartData;

    await nextTick();

    expect(findColumnChart().props('bars')).toEqual(mockBarsData);
  });

  it('fetches data when filters are applied', async () => {
    store.state.issueAnalytics.filters = '?hello=world';

    await nextTick();

    expect(mockDispatch).toHaveBeenCalledTimes(2);
    expect(mockDispatch.mock.calls[1]).toEqual(['issueAnalytics/fetchChartData', TEST_HOST]);
  });

  it('renders loading state when loading', async () => {
    store.state.issueAnalytics.loading = true;

    await nextTick();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(findChartContainer().exists()).toBe(false);
  });

  it('renders empty state when chart data is empty', async () => {
    store.state.issueAnalytics.chartData = {};

    await nextTick();

    expect(findEmptyState().props('emptyStateType')).toBe('noData');
    expect(findChartContainer().exists()).toBe(false);
  });

  it('renders filters empty state when filters are applied and chart data is empty', async () => {
    store.state.issueAnalytics.chartData = {};
    store.state.issueAnalytics.filters = '?hello=world';

    await nextTick();

    expect(findEmptyState().props('emptyStateType')).toBe('noDataWithFilters');
    expect(findChartContainer().exists()).toBe(false);
  });

  it('emits "hasNoData" event when chart data is empty', async () => {
    store.state.issueAnalytics.chartData = {};

    await nextTick();

    expect(wrapper.emitted('hasNoData')).toBeDefined();
  });
});
