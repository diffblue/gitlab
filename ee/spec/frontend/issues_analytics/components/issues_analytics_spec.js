import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuesAnalytics from 'ee/issues_analytics/components/issues_analytics.vue';
import IssuesAnalyticsChart from 'ee/issues_analytics/components/issues_analytics_chart.vue';
import IssuesAnalyticsTable from 'ee/issues_analytics/components/issues_analytics_table.vue';
import { createStore } from 'ee/issues_analytics/stores';

const mockFilterManagerSetup = jest.fn();
jest.mock('ee/issues_analytics/filtered_search_issues_analytics', () =>
  jest.fn().mockImplementation(() => ({
    setup: mockFilterManagerSetup,
  })),
);

Vue.use(Vuex);

describe('IssuesAnalytics', () => {
  let wrapper;
  let store;

  const defaultProvide = {
    hasIssuesCompletedFeature: false,
  };

  const findIssuesAnalyticsChart = () => wrapper.findComponent(IssuesAnalyticsChart);
  const findIssuesAnalyticsTable = () => wrapper.findComponent(IssuesAnalyticsTable);

  const createComponent = ({ props = {}, provide = defaultProvide } = {}) => {
    const filterBlockEl = document.querySelector('#mock-filter');

    store = createStore();

    wrapper = shallowMountExtended(IssuesAnalytics, {
      propsData: {
        filterBlockEl,
        ...props,
      },
      provide,
      store,
    });
  };

  describe('chart', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Issues Analytics chart', () => {
      expect(findIssuesAnalyticsChart().exists()).toBe(true);
    });
  });

  describe('table', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Issues Analytics table', () => {
      expect(findIssuesAnalyticsTable().exists()).toBe(true);
    });
  });
});
