import {
  buildDefaultDashboardFilters,
  dateRangeOptionToFilter,
  filtersToQueryParams,
  getDateRangeOption,
  isEmptyPanelData,
  availableVisualizationsValidator,
  getDashboardConfig,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { parsePikadayDate } from '~/lib/utils/datetime_utility';
import {
  CUSTOM_DATE_RANGE_KEY,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
} from 'ee/vue_shared/components/customizable_dashboard/filters/constants';
import productAnalyticsDashboardFragment from 'ee/analytics/analytics_dashboards/graphql/fragments/product_analytics_dashboard.fragment.graphql';

import { createMockClient } from 'helpers/mock_apollo_helper';
import { TYPENAME_PRODUCT_ANALYTICS_DASHBOARD } from 'ee/analytics/analytics_dashboards/graphql/constants';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
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
  it('returns true when there are no available visualizations', () => {
    const result = availableVisualizationsValidator({});
    expect(result).toBe(true);
  });

  it('returns true when the options have the required keys', () => {
    const result = availableVisualizationsValidator({
      foo: { loading: false, visualizations: [] },
    });
    expect(result).toBe(true);
  });

  it('returns false when the options dot not have the required keys', () => {
    const result = availableVisualizationsValidator({
      foo: { loading: false, bar: [] },
    });
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
          id: 1,
          queryOverrides: null,
          title: 'Test A',
          visualization: 'cube_line_chart',
        },
        {
          gridAttributes: {
            height: 4,
            width: 2,
          },
          id: 2,
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
  let mockWriteFragment;
  const projectId = '1';
  const dashboardSlug = 'analytics_overview';
  const dashboardRef = `${TYPENAME_PRODUCT_ANALYTICS_DASHBOARD}:{"slug":"${dashboardSlug}" }`;
  const projectRef = `${TYPENAME_PROJECT}:${convertToGraphQLId(TYPENAME_PROJECT, projectId)}`;

  beforeEach(() => {
    apolloClient = createMockClient(
      [],
      {},
      {
        dataIdFromObject: jest.fn(({ slug }) => (slug ? dashboardRef : projectRef)),
      },
    );

    mockWriteFragment = jest.fn();
    apolloClient.writeFragment = mockWriteFragment;
  });

  it('adds a new dashboard fragment to the cache', () => {
    updateApolloCache(apolloClient, projectId, dashboardSlug, dashboard);

    expect(mockWriteFragment).toHaveBeenCalledWith(
      expect.objectContaining({
        id: dashboardRef,
        fragment: productAnalyticsDashboardFragment,
        data: expect.objectContaining({
          slug: dashboardSlug,
          title: dashboard.title,
          panels: expect.objectContaining({
            nodes: expect.arrayContaining([
              expect.objectContaining({
                id: 1,
                visualization: expect.objectContaining({
                  type: 'LineChart',
                  slug: 'cube_line_chart',
                  title: 'Cube line chart',
                }),
              }),
              expect.objectContaining({
                id: 2,
                visualization: expect.objectContaining({
                  type: 'LineChart',
                  slug: 'cube_line_chart',
                  title: 'Cube line chart',
                }),
              }),
            ]),
          }),
        }),
      }),
    );
  });

  it('links new dashboard to project', () => {
    apolloClient.cache.modify = jest.fn();

    updateApolloCache(apolloClient, projectId, dashboardSlug, dashboard);

    expect(apolloClient.cache.modify).toHaveBeenCalledWith(
      expect.objectContaining({
        id: projectRef,
      }),
    );

    const modifyCallback =
      apolloClient.cache.modify.mock.calls[0][0].fields.productAnalyticsDashboards;

    const modifiedData = modifyCallback({ nodes: [{ __ref: 'some/existing/dashboardRef' }] });
    expect(modifiedData).toEqual({
      nodes: [{ __ref: 'some/existing/dashboardRef' }, { __ref: dashboardRef }],
    });
  });
});
