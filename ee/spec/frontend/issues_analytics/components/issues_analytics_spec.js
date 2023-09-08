import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuesAnalytics from 'ee/issues_analytics/components/issues_analytics.vue';
import IssuesAnalyticsChart from 'ee/issues_analytics/components/issues_analytics_chart.vue';
import TotalIssuesAnalyticsChart from 'ee/issues_analytics/components/total_issues_analytics_chart.vue';
import IssuesAnalyticsTable from 'ee/issues_analytics/components/issues_analytics_table.vue';
import { createStore } from 'ee/issues_analytics/stores';
import { useFakeDate } from 'helpers/fake_date';
import { mockFilters, mockOriginalFilters } from '../mock_data';

const mockFilterManagerSetup = jest.fn();
jest.mock('ee/issues_analytics/filtered_search_issues_analytics', () =>
  jest.fn().mockImplementation(() => ({
    setup: mockFilterManagerSetup,
  })),
);

Vue.use(Vuex);

describe('IssuesAnalytics', () => {
  useFakeDate(2023, 7, 1);

  let wrapper;
  let store;

  const findIssuesAnalyticsChart = () => wrapper.findComponent(IssuesAnalyticsChart);
  const findTotalIssuesAnalyticsChart = () => wrapper.findComponent(TotalIssuesAnalyticsChart);
  const findIssuesAnalyticsTable = () => wrapper.findComponent(IssuesAnalyticsTable);

  const createComponent = ({
    props = {},
    provide = {},
    hasIssuesCompletedFeature = false,
    issuesCompletedAnalyticsFeatureFlag = false,
  } = {}) => {
    const filterBlockEl = document.querySelector('#mock-filter');

    store = createStore();

    wrapper = shallowMountExtended(IssuesAnalytics, {
      propsData: {
        filterBlockEl,
        ...props,
      },
      provide: {
        hasIssuesCompletedFeature,
        glFeatures: {
          issuesCompletedAnalyticsFeatureFlag,
        },
        ...provide,
      },
      store,
    });
  };

  describe('chart', () => {
    it.each`
      hasIssuesCompletedFeature | issuesCompletedAnalyticsFeatureFlag | shouldShowTotalIssuesAnalyticsChart | shouldShowIssuesAnalyticsChart
      ${true}                   | ${true}                             | ${true}                             | ${false}
      ${false}                  | ${true}                             | ${false}                            | ${true}
      ${true}                   | ${false}                            | ${false}                            | ${true}
      ${false}                  | ${false}                            | ${false}                            | ${true}
    `(
      'renders the correct chart component when hasIssuesCompletedFeature=$hasIssuesCompletedFeature and issuesCompletedAnalyticsFeatureFlag=$issuesCompletedAnalyticsFeatureFlag',
      ({
        hasIssuesCompletedFeature,
        issuesCompletedAnalyticsFeatureFlag,
        shouldShowTotalIssuesAnalyticsChart,
        shouldShowIssuesAnalyticsChart,
      }) => {
        createComponent({
          hasIssuesCompletedFeature,
          issuesCompletedAnalyticsFeatureFlag,
        });

        expect(findTotalIssuesAnalyticsChart().exists()).toBe(shouldShowTotalIssuesAnalyticsChart);
        expect(findIssuesAnalyticsChart().exists()).toBe(shouldShowIssuesAnalyticsChart);
      },
    );

    describe('Total Issues Analytics chart', () => {
      beforeEach(() => {
        createComponent({
          hasIssuesCompletedFeature: true,
          issuesCompletedAnalyticsFeatureFlag: true,
        });
      });

      it('passes transformed global page filters to the `filters` prop', async () => {
        await store.dispatch('issueAnalytics/setFilters', mockOriginalFilters);

        expect(findTotalIssuesAnalyticsChart().props('filters')).toEqual(mockFilters);
      });

      it('passes correct default end date to `endDate` prop', () => {
        const expectedEndDate = new Date();

        expect(findTotalIssuesAnalyticsChart().props('endDate')).toEqual(expectedEndDate);
      });

      it('passes correct default date twelve months in the past to `startDate` prop', () => {
        const expectedStartDate = new Date('2022-08-01T00:00:00.000Z');

        expect(findTotalIssuesAnalyticsChart().props('startDate')).toEqual(expectedStartDate);
      });

      it('passes correct date to `startDate` prop when `months_back` filter is defined', async () => {
        const expectedStartDate = new Date('2023-05-01T00:00:00.000Z');

        await store.dispatch('issueAnalytics/setFilters', { months_back: 3 });

        expect(findTotalIssuesAnalyticsChart().props('startDate')).toEqual(expectedStartDate);
      });
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
