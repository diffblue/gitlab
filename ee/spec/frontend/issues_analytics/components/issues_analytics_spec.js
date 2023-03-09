import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import IssuesAnalytics from 'ee/issues_analytics/components/issues_analytics.vue';
import IssuesAnalyticsTable from 'ee/issues_analytics/components/issues_analytics_table.vue';
import { createStore } from 'ee/issues_analytics/stores';
import { TEST_HOST } from 'helpers/test_constants';

const mockFilterManagerSetup = jest.fn();
jest.mock('ee/issues_analytics/filtered_search_issues_analytics', () =>
  jest.fn().mockImplementation(() => ({
    setup: mockFilterManagerSetup,
  })),
);

Vue.use(Vuex);

describe('Issue Analytics component', () => {
  let wrapper;
  let store;
  let mountComponent;
  let axiosMock;
  const mockChartData = { '2017-11': 0, '2017-12': 2 };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    mountComponent = (data) => {
      setHTMLFixture('<div id="mock-filter"></div>');
      const propsData = data || {
        endpoint: TEST_HOST,
        issuesApiEndpoint: `${TEST_HOST}/api/issues`,
        issuesPageEndpoint: `${TEST_HOST}/issues`,
        filterBlockEl: document.querySelector('#mock-filter'),
        noDataEmptyStateSvgPath: 'svg',
        filtersEmptyStateSvgPath: 'svg',
      };

      return shallowMount(IssuesAnalytics, {
        propsData,
        stubs: {
          GlColumnChart: true,
        },
        store,
      });
    };

    wrapper = mountComponent();
  });

  afterEach(() => {
    axiosMock.restore();

    resetHTMLFixture();
  });

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findChartContainer = () => wrapper.find('.issues-analytics-chart');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  it('fetches chart data when mounted', () => {
    expect(store.dispatch).toHaveBeenCalledWith('issueAnalytics/fetchChartData', TEST_HOST);
  });

  it('renders loading state when loading', async () => {
    wrapper.vm.$store.state.issueAnalytics.loading = true;

    await nextTick();
    expect(findLoadingIcon().exists()).toBe(true);
    expect(findChartContainer().exists()).toBe(false);
  });

  it('renders chart when data is present', async () => {
    wrapper.vm.$store.state.issueAnalytics.chartData = mockChartData;

    await nextTick();
    expect(findChartContainer().exists()).toBe(true);
  });

  it('fetches data when filters are applied', async () => {
    wrapper.vm.$store.state.issueAnalytics.filters = '?hello=world';

    await nextTick();
    expect(store.dispatch).toHaveBeenCalledTimes(2);
    expect(store.dispatch.mock.calls[1]).toEqual(['issueAnalytics/fetchChartData', TEST_HOST]);
  });

  it('renders empty state when chart data is empty', async () => {
    wrapper.vm.$store.state.issueAnalytics.chartData = {};

    await nextTick();
    expect(findEmptyState().exists()).toBe(true);
    expect(wrapper.vm.showNoDataEmptyState).toBe(true);
  });

  it('renders filters empty state when filters are applied and chart data is empty', async () => {
    wrapper.vm.$store.state.issueAnalytics.chartData = {};
    wrapper.vm.$store.state.issueAnalytics.filters = '?hello=world';

    await nextTick();
    expect(findEmptyState().exists()).toBe(true);
    expect(wrapper.vm.showFiltersEmptyState).toBe(true);
  });

  it('renders the issues table', () => {
    expect(wrapper.findComponent(IssuesAnalyticsTable).exists()).toBe(true);
  });
});
