import VueApollo from 'vue-apollo';
import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TotalIssuesAnalyticsChart from 'ee/issues_analytics/components/total_issues_analytics_chart.vue';
import IssuesAnalyticsEmptyState from 'ee/issues_analytics/components/issues_analytics_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import issuesAnalyticsCountsQueryBuilder from 'ee/issues_analytics/graphql/issues_analytics_counts_query_builder';
import { TOTAL_ISSUES_ANALYTICS_CHART_COLOR_PALETTE } from 'ee/issues_analytics/constants';
import {
  generateMockIssuesAnalyticsCountsEmptyResponseData,
  generateMockIssuesAnalyticsCountsResponseData,
  mockIssuesAnalyticsCountsChartData,
  mockIssuesAnalyticsCountsEndDate,
  mockIssuesAnalyticsCountsStartDate,
  mockFilters,
  mockEmptyFilters,
} from '../mock_data';
import { mockGraphqlIssuesAnalyticsCountsResponse } from '../helpers';

jest.mock('@sentry/browser');

Vue.use(VueApollo);

describe('TotalIssuesAnalyticsChart', () => {
  let wrapper;
  let mockApollo;
  let issuesAnalyticsCountsSuccess;

  const fullPath = 'toolbox';
  const mockGroupBy = ['Jul', 'Aug'];
  const queryError = jest.fn().mockRejectedValueOnce(new Error('Something went wrong'));
  const mockDataNullResponse = mockGraphqlIssuesAnalyticsCountsResponse({ mockDataResponse: null });
  const mockDataEmptyResponse = mockGraphqlIssuesAnalyticsCountsResponse({
    mockDataResponse: generateMockIssuesAnalyticsCountsEmptyResponseData(),
  });
  const mockXAxisTitle = 'Last 2 months (Jul 2023 – Aug 2023)';

  const createComponent = async ({
    props = {},
    startDate = mockIssuesAnalyticsCountsStartDate,
    endDate = mockIssuesAnalyticsCountsEndDate,
    filters = {},
    type = 'group',
    issuesAnalyticsCountsResolver,
  } = {}) => {
    const isProject = type === 'project';
    const mockDataResponse = generateMockIssuesAnalyticsCountsResponseData(isProject);

    issuesAnalyticsCountsSuccess = mockGraphqlIssuesAnalyticsCountsResponse({
      mockDataResponse,
    });
    mockApollo = createMockApollo([
      [
        issuesAnalyticsCountsQueryBuilder(startDate, endDate, isProject),
        issuesAnalyticsCountsResolver || issuesAnalyticsCountsSuccess,
      ],
    ]);

    wrapper = shallowMountExtended(TotalIssuesAnalyticsChart, {
      apolloProvider: mockApollo,
      propsData: {
        startDate,
        endDate,
        filters,
        ...props,
      },
      provide: {
        fullPath,
        type,
      },
    });

    await waitForPromises();
  };

  const findTotalIssuesAnalyticsChart = () => wrapper.findComponent(GlStackedColumnChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(IssuesAnalyticsEmptyState);

  afterEach(() => {
    mockApollo = null;
  });

  describe.each(['group', 'project'])(
    'when the issuesAnalyticsCountsData query type is %s',
    (type) => {
      describe('and filters are not set', () => {
        beforeEach(async () => {
          await createComponent({ type, filters: mockEmptyFilters });
        });

        it('fetches Issues Analytics counts without filters', () => {
          const { monthsBack, ...filters } = mockEmptyFilters;

          expect(issuesAnalyticsCountsSuccess).toHaveBeenCalledTimes(1);
          expect(issuesAnalyticsCountsSuccess).toHaveBeenCalledWith({
            fullPath,
            ...filters,
          });
        });
      });

      describe('and filters are set', () => {
        beforeEach(async () => {
          await createComponent({ type, filters: mockFilters });
        });

        it('fetches Issues Analytics counts with filters', () => {
          const { monthsBack, ...filters } = mockFilters;

          expect(issuesAnalyticsCountsSuccess).toHaveBeenCalledTimes(1);
          expect(issuesAnalyticsCountsSuccess).toHaveBeenCalledWith({
            fullPath,
            ...filters,
          });
        });
      });
    },
  );

  describe('when fetching data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should display loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when fetching data is successful', () => {
    it('should render chart', async () => {
      await createComponent();

      expect(findTotalIssuesAnalyticsChart().exists()).toBe(true);
    });

    it('should display chart header', async () => {
      await createComponent();

      expect(wrapper.findByText('Overview').exists()).toBe(true);
    });

    it.each`
      prop               | propValue
      ${'bars'}          | ${mockIssuesAnalyticsCountsChartData}
      ${'presentation'}  | ${'tiled'}
      ${'groupBy'}       | ${mockGroupBy}
      ${'xAxisType'}     | ${'category'}
      ${'xAxisTitle'}    | ${mockXAxisTitle}
      ${'yAxisTitle'}    | ${'Issues Opened vs Closed'}
      ${'customPalette'} | ${TOTAL_ISSUES_ANALYTICS_CHART_COLOR_PALETTE}
    `("sets '$prop' prop to '$propValue' in the chart", async ({ prop, propValue }) => {
      await createComponent();

      expect(findTotalIssuesAnalyticsChart().props(prop)).toStrictEqual(propValue);
    });

    it('displays the correct x-axis title when date range is month to date', async () => {
      const startDate = new Date('2023-07-01T00:00:00.000Z');
      const endDate = new Date('2023-07-31T00:00:00.000Z');

      await createComponent({ startDate, endDate });

      expect(findTotalIssuesAnalyticsChart().props('xAxisTitle')).toBe('This month (Jul 2023)');
    });
  });

  describe('when fetching data fails', () => {
    beforeEach(async () => {
      await createComponent({ issuesAnalyticsCountsResolver: queryError });
    });

    it('should display alert component', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('Failed to load chart. Please try again.');
    });

    it('should log error to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledTimes(1);
    });

    it('should not display chart', () => {
      expect(findTotalIssuesAnalyticsChart().exists()).toBe(false);
    });
  });

  describe('when there is no data', () => {
    describe('and filters are not applied', () => {
      it.each`
        description            | response
        ${'response is null'}  | ${mockDataNullResponse}
        ${'response is empty'} | ${mockDataEmptyResponse}
      `(
        'displays empty state when $description and emits "hideFilteredSearchBar" event',
        async ({ response }) => {
          await createComponent({
            filters: mockEmptyFilters,
            issuesAnalyticsCountsResolver: response,
          });

          expect(findEmptyState().props('emptyStateType')).toBe('noData');
          expect(wrapper.emitted('hideFilteredSearchBar')).toHaveLength(1);
        },
      );
    });

    describe('and filters are applied', () => {
      beforeEach(async () => {
        await createComponent({
          filters: mockFilters,
          issuesAnalyticsCountsResolver: mockDataEmptyResponse,
        });

        it('displays filters empty state', () => {
          expect(findEmptyState().props('emptyStateType')).toBe('noDataWithFilters');
        });

        it('should not emit "hideFilteredSearchBar" event', () => {
          expect(wrapper.emitted('hideFilteredSearchBar')).toBeUndefined();
        });
      });
    });
  });
});
