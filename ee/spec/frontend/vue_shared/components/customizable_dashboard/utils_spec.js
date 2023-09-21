import {
  buildDefaultDashboardFilters,
  dateRangeOptionToFilter,
  filtersToQueryParams,
  getDateRangeOption,
  isEmptyPanelData,
  availableVisualizationsValidator,
  getDashboardConfig,
  updateApolloCache,
  getVisualizationCategory,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { parsePikadayDate } from '~/lib/utils/datetime_utility';
import {
  CUSTOM_DATE_RANGE_KEY,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
} from 'ee/vue_shared/components/customizable_dashboard/filters/constants';
import getProductAnalyticsDashboardQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_product_analytics_dashboard.query.graphql';
import getAllProductAnalyticsDashboardsQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_all_product_analytics_dashboards.query.graphql';
import { createMockClient } from 'helpers/mock_apollo_helper';
import {
  CATEGORY_SINGLE_STATS,
  CATEGORY_CHARTS,
  CATEGORY_TABLES,
} from 'ee/vue_shared/components/customizable_dashboard/constants';
import {
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE,
  TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  getGraphQLDashboard,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { mockDateRangeFilterChangePayload, dashboard } from './mock_data';

const option = DATE_RANGE_OPTIONS[0];

describe('getDateRangeOption', () => {
  it('should return the date range option', () => {
    expect(getDateRangeOption(option.key)).toStrictEqual(option);
  });
});

describe('dateRangeOptionToFilter', () => {
  it('filters data by `name` for the provided search term', () => {
    expect(dateRangeOptionToFilter(option)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });
});

describe('buildDefaultDashboardFilters', () => {
  it('returns the default option for an empty query string', () => {
    const defaultOption = DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX];

    expect(buildDefaultDashboardFilters('')).toStrictEqual({
      startDate: defaultOption.startDate,
      endDate: defaultOption.endDate,
      dateRangeOption: defaultOption.key,
    });
  });

  it('returns the option that matches the date_range_option', () => {
    const queryString = `date_range_option=${option.key}`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });

  it('returns the a custom range when the query string is custom and contains dates', () => {
    const queryString = `date_range_option=${CUSTOM_DATE_RANGE_KEY}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: parsePikadayDate('2023-01-10'),
      endDate: parsePikadayDate('2023-02-08'),
      dateRangeOption: CUSTOM_DATE_RANGE_KEY,
    });
  });

  it('returns the option that matches the date_range_option and ignores the query dates when the option is not custom', () => {
    const queryString = `date_range_option=${option.key}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });
});

describe('filtersToQueryParams', () => {
  const customOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: CUSTOM_DATE_RANGE_KEY,
  };

  const nonCustomOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: 'foobar',
  };

  it('returns the dateRangeOption with null date params when the option is not custom', () => {
    expect(filtersToQueryParams(nonCustomOption)).toStrictEqual({
      date_range_option: 'foobar',
      end_date: null,
      start_date: null,
    });
  });

  it('returns the dateRangeOption and date params when the option is custom', () => {
    expect(filtersToQueryParams(customOption)).toStrictEqual({
      date_range_option: CUSTOM_DATE_RANGE_KEY,
      start_date: '2016-01-01',
      end_date: '2016-02-01',
    });
  });
});

describe('isEmptyPanelData', () => {
  it.each`
    visualizationType | value  | expected
    ${'SingleStat'}   | ${[]}  | ${false}
    ${'SingleStat'}   | ${1}   | ${false}
    ${'LineChart'}    | ${[]}  | ${true}
    ${'LineChart'}    | ${[1]} | ${false}
  `(
    'returns $expected for visualization "$visualizationType" with value "$value"',
    ({ visualizationType, value, expected }) => {
      const result = isEmptyPanelData(visualizationType, value);
      expect(result).toBe(expected);
    },
  );
});

describe('availableVisualizationsValidator', () => {
  it('returns true when the object contains all properties', () => {
    const result = availableVisualizationsValidator({ loading: false, visualizations: [] });
    expect(result).toBe(true);
  });

  it('returns false when the object does not contain all properties', () => {
    const result = availableVisualizationsValidator({ visualizations: [] });
    expect(result).toBe(false);
  });
});

describe('getDashboardConfig', () => {
  it('maps dashboard to expected value', () => {
    const result = getDashboardConfig(dashboard);

    expect(result).toMatchObject({
      id: 'analytics_overview',
      panels: [
        {
          gridAttributes: {
            height: 3,
            width: 3,
          },
          queryOverrides: null,
          title: 'Test A',
          visualization: 'cube_line_chart',
        },
        {
          gridAttributes: {
            height: 4,
            width: 2,
          },
          queryOverrides: {
            limit: 200,
          },
          title: 'Test B',
          visualization: 'cube_line_chart',
        },
      ],
      title: 'Analytics Overview',
    });
  });

  ['userDefined', 'slug'].forEach((omitted) => {
    it(`omits "${omitted}" dashboard property`, () => {
      const result = getDashboardConfig(dashboard);

      expect(result[omitted]).not.toBeDefined();
    });
  });
});

describe('updateApolloCache', () => {
  let apolloClient;
  let mockReadQuery;
  let mockWriteQuery;
  const projectId = '1';
  const dashboardSlug = 'analytics_overview';
  const projectFullpath = TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath;

  const setMockCache = (mockDashboardDetails, mockDashboardsList) => {
    mockReadQuery.mockImplementation(({ query }) => {
      if (query === getProductAnalyticsDashboardQuery) {
        return mockDashboardDetails;
      }
      if (query === getAllProductAnalyticsDashboardsQuery) {
        return mockDashboardsList;
      }

      return null;
    });
  };

  beforeEach(() => {
    apolloClient = createMockClient();

    mockReadQuery = jest.fn();
    mockWriteQuery = jest.fn();
    apolloClient.readQuery = mockReadQuery;
    apolloClient.writeQuery = mockWriteQuery;
  });

  describe('dashboard details cache', () => {
    it('updates an existing dashboard', () => {
      const existingDashboard = getGraphQLDashboard(
        {
          slug: 'some_existing_dash',
          title: 'some existing title',
        },
        false,
      );
      const existingDetailsCache = {
        ...TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data,
      };
      existingDetailsCache.project.customizableDashboards.nodes = [existingDashboard];

      setMockCache(existingDetailsCache, null);

      updateApolloCache(
        apolloClient,
        projectId,
        existingDashboard.slug,
        {
          ...existingDashboard,
          title: 'some new title',
        },
        projectFullpath,
      );

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getProductAnalyticsDashboardQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    title: 'some new title',
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('does not update for new dashboards where cache is empty', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      updateApolloCache(apolloClient, projectId, dashboardSlug, dashboard, projectFullpath);

      expect(mockWriteQuery).not.toHaveBeenCalledWith(
        expect.objectContaining({ query: getProductAnalyticsDashboardQuery }),
      );
    });
  });

  describe('dashboards list', () => {
    it('adds a new dashboard to the dashboards list', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      updateApolloCache(apolloClient, projectId, dashboardSlug, dashboard, projectFullpath);

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getAllProductAnalyticsDashboardsQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    slug: dashboardSlug,
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('updates an existing dashboard on the dashboards list', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      const existingDashboards =
        TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data.project.customizableDashboards.nodes;

      const updatedDashboard = {
        ...existingDashboards.at(0),
        title: 'some new title',
      };

      updateApolloCache(apolloClient, projectId, dashboardSlug, updatedDashboard, projectFullpath);

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getAllProductAnalyticsDashboardsQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    title: 'some new title',
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('does not update dashboard list cache when it has not yet been populated', () => {
      setMockCache(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data, null);

      updateApolloCache(apolloClient, projectId, dashboardSlug, dashboard, projectFullpath);

      expect(mockWriteQuery).not.toHaveBeenCalledWith(
        expect.objectContaining({ query: getAllProductAnalyticsDashboardsQuery }),
      );
    });
  });
});

describe('getVisualizationCategory', () => {
  it.each`
    category                 | type
    ${CATEGORY_SINGLE_STATS} | ${'SingleStat'}
    ${CATEGORY_TABLES}       | ${'DataTable'}
    ${CATEGORY_CHARTS}       | ${'LineChart'}
    ${CATEGORY_CHARTS}       | ${'FooBar'}
  `('returns $category when the visualization type is $type', ({ category, type }) => {
    expect(getVisualizationCategory({ type })).toBe(category);
  });
});
