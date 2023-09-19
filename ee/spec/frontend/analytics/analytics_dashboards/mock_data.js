import { TEST_HOST } from 'spec/test_constants';

export const TEST_TRACKING_KEY = 'gid://gitlab/Project/2';

export const TEST_COLLECTOR_HOST = TEST_HOST;

export const TEST_EMPTY_DASHBOARD_SVG_PATH = 'illustration/empty-dashboard';

export const TEST_ROUTER_BACK_HREF = 'go-back';

export const TEST_CUSTOM_DASHBOARDS_PROJECT = {
  fullPath: 'test/test-dashboards',
  id: 123,
  name: 'test-dashboards',
};

export const TEST_VISUALIZATION = () => ({
  version: 1,
  type: 'LineChart',
  slug: 'test_visualization',
  data: {
    type: 'cube_analytics',
    query: {
      measures: ['TrackedEvents.count'],
      timeDimensions: [
        {
          dimension: 'TrackedEvents.utcTime',
          granularity: 'day',
        },
      ],
      limit: 100,
      timezone: 'UTC',
      filters: [],
      dimensions: [],
    },
  },
});

export const TEST_DASHBOARD_GRAPHQL_404_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const getGraphQLDashboard = (options = {}, withPanels = true) => {
  const dashboard = {
    slug: '',
    title: '',
    userDefined: false,
    description: 'Understand your audience',
    __typename: 'CustomizableDashboard',
    ...options,
  };

  if (withPanels) {
    return {
      ...dashboard,
      panels: {
        nodes: [
          {
            title: 'Daily Active Users',
            gridAttributes: {
              yPos: 1,
              xPos: 0,
              width: 6,
              height: 5,
            },
            queryOverrides: {
              limit: 200,
            },
            visualization: {
              slug: 'line_chart',
              type: 'LineChart',
              options: {
                xAxis: {
                  name: 'Time',
                  type: 'time',
                },
                yAxis: {
                  name: 'Counts',
                  type: 'time',
                },
              },
              data: {
                type: 'cube_analytics',
                query: {
                  measures: ['TrackedEvents.uniqueUsersCount'],
                  timeDimensions: [
                    {
                      dimension: 'TrackedEvents.derivedTstamp',
                      granularity: 'day',
                    },
                  ],
                  limit: 100,
                  timezone: 'UTC',
                  filters: [],
                  dimensions: [],
                },
              },
              errors: null,
              __typename: 'CustomizableDashboardVisualization',
            },
            __typename: 'CustomizableDashboardPanel',
          },
        ],
        __typename: 'CustomizableDashboardPanelConnection',
      },
    };
  }

  return dashboard;
};

export const TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/73',
      customizableDashboardVisualizations: {
        nodes: [
          {
            slug: 'another_one',
            type: 'SingleStat',
            data: {
              type: 'cube_analytics',
              query: {
                measures: ['TrackedEvents.count'],
                filters: [
                  {
                    member: 'TrackedEvents.event',
                    operator: 'equals',
                    values: ['click'],
                  },
                ],
                limit: 100,
                timezone: 'UTC',
                dimensions: [],
                timeDimensions: [],
              },
            },
            options: {},
            __typename: 'CustomizableDashboardVisualization',
          },
        ],
      },
    },
  },
};

export const TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [
          getGraphQLDashboard({
            slug: 'custom_dashboard',
            title: 'Custom Dashboard',
            userDefined: true,
          }),
        ],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const TEST_CUSTOM_VSD_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [
          getGraphQLDashboard({
            slug: 'value_stream_dashboard',
            title: 'Value Stream Dashboard',
            userDefined: false,
          }),
        ],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [getGraphQLDashboard({ slug: 'audience', title: 'Audience' })],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [
          getGraphQLDashboard({ slug: 'audience', title: 'Audience' }, false),
          getGraphQLDashboard({ slug: 'behavior', title: 'Behavior' }, false),
          getGraphQLDashboard(
            { slug: 'new_dashboard', title: 'new_dashboard', userDefined: true },
            false,
          ),
        ],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const mockResultSet = {
  seriesNames: () => [
    {
      title: 'pageview, TrackedEvents Count',
      key: 'pageview,TrackedEvents.count',
      yValues: ['pageview', 'TrackedEvents.count'],
    },
  ],
  chartPivot: () => [
    {
      x: '2022-11-09T00:00:00.000',
      xValues: ['2022-11-09T00:00:00.000'],
      'pageview,TrackedEvents.count': 55,
    },
    {
      x: '2022-11-10T00:00:00.000',
      xValues: ['2022-11-10T00:00:00.000'],
      'pageview,TrackedEvents.count': 14,
    },
  ],
  tableColumns: () => [
    {
      key: 'TrackedEvents.utcTime.day',
      title: 'TrackedEvents Utc Time',
      shortTitle: 'Utc Time',
      type: 'time',
      dataIndex: 'TrackedEvents.utcTime.day',
    },
    {
      key: 'TrackedEvents.eventType',
      title: 'TrackedEvents Event Type',
      shortTitle: 'Event Type',
      type: 'string',
      dataIndex: 'TrackedEvents.eventType',
    },
    {
      key: 'TrackedEvents.count',
      type: 'number',
      dataIndex: 'TrackedEvents.count',
      title: 'TrackedEvents Count',
      shortTitle: 'Count',
    },
  ],
  tablePivot: () => [
    {
      'TrackedEvents.utcTime.day': '2022-11-09T00:00:00.000',
      'TrackedEvents.eventType': 'pageview',
      'TrackedEvents.count': '55',
    },
    {
      'TrackedEvents.utcTime.day': '2022-11-10T00:00:00.000',
      'TrackedEvents.eventType': 'pageview',
      'TrackedEvents.count': '14',
    },
  ],
  rawData: () => [
    {
      'TrackedEvents.userLanguage': 'en-US',
      'TrackedEvents.count': '36',
      'TrackedEvents.url': 'https://example.com/us',
    },
    {
      'TrackedEvents.userLanguage': 'es-ES',
      'TrackedEvents.count': '60',
      'TrackedEvents.url': 'https://example.com/es',
    },
  ],
};

export const mockTableWithLinksResultSet = {
  tableColumns: () => [
    {
      key: 'TrackedEvents.docPath',
      title: 'Tracked Events Doc Path',
      shortTitle: 'Doc Path',
      type: 'string',
      dataIndex: 'TrackedEvents.docPath',
    },
    {
      key: 'TrackedEvents.url',
      title: 'Tracked Events Url',
      shortTitle: 'Url',
      type: 'string',
      dataIndex: 'TrackedEvents.url',
    },
    {
      key: 'TrackedEvents.pageViewsCount',
      type: 'number',
      dataIndex: 'TrackedEvents.pageViewsCount',
      title: 'Tracked Events Page Views Count',
      shortTitle: 'Page Views Count',
    },
  ],
  tablePivot: () => [
    {
      'TrackedEvents.docPath': '/foo',
      'TrackedEvents.url': 'https://example.com/foo',
      'TrackedEvents.pageViewsCount': '1',
    },
  ],
};

export const mockResultSetWithNullValues = {
  rawData: () => [
    {
      'TrackedEvents.userLanguage': null,
      'TrackedEvents.count': null,
      'TrackedEvents.url': null,
    },
  ],
};

export const mockFilters = {
  startDate: new Date('2015-01-01'),
  endDate: new Date('2016-01-01'),
};

export const mockMetaData = {
  cubes: [
    {
      name: 'TrackedEvents',
      title: 'Tracked Events',
      connectedComponent: 2,
      measures: [
        {
          name: 'TrackedEvents.count',
          title: 'Tracked Events Count',
          shortTitle: 'Count',
          cumulativeTotal: false,
          cumulative: false,
          type: 'number',
          aggType: 'count',
          drillMembers: ['TrackedEvents.eventId', 'TrackedEvents.pageTitle'],
          drillMembersGrouped: {
            measures: [],
            dimensions: ['TrackedEvents.eventId', 'TrackedEvents.pageTitle'],
          },
          isVisible: true,
        },
      ],
      dimensions: [
        {
          name: 'TrackedEvents.pageUrlhosts',
          title: 'Tracked Events Page Urlhosts',
          type: 'string',
          shortTitle: 'Page Urlhosts',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.pageUrlpath',
          title: 'Tracked Events Page Urlpath',
          type: 'string',
          shortTitle: 'Page Urlpath',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.event',
          title: 'Tracked Events Event',
          type: 'string',
          shortTitle: 'Event',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.pageTitle',
          title: 'Tracked Events Page Title',
          type: 'string',
          shortTitle: 'Page Title',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.osFamily',
          title: 'Tracked Events Os Family',
          type: 'string',
          shortTitle: 'Os Family',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.osName',
          title: 'Tracked Events Os Name',
          type: 'string',
          shortTitle: 'Os Name',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.osVersion',
          title: 'Tracked Events Os Version',
          type: 'string',
          shortTitle: 'Os Version',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.osVersionMajor',
          title: 'Tracked Events Os Version Major',
          type: 'string',
          shortTitle: 'Os Version Major',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.agentName',
          title: 'Tracked Events Agent Name',
          type: 'string',
          shortTitle: 'Agent Name',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.agentVersion',
          title: 'Tracked Events Agent Version',
          type: 'string',
          shortTitle: 'Agent Version',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.pageReferrer',
          title: 'Tracked Events Page Referrer',
          type: 'string',
          shortTitle: 'Page Referrer',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.pageUrl',
          title: 'Tracked Events Page Url',
          type: 'string',
          shortTitle: 'Page Url',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.useragent',
          title: 'Tracked Events Useragent',
          type: 'string',
          shortTitle: 'Useragent',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.userId',
          title: 'Tracked Events User Id',
          type: 'string',
          shortTitle: 'User Id',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.derivedTstamp',
          title: 'Tracked Events Derived Tstamp',
          type: 'time',
          shortTitle: 'Derived Tstamp',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.browserLanguage',
          title: 'Tracked Events Browser Language',
          type: 'string',
          shortTitle: 'Browser Language',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.documentLanguage',
          title: 'Tracked Events Document Language',
          type: 'string',
          shortTitle: 'Document Language',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.viewportSize',
          title: 'Tracked Events Viewport Size',
          type: 'string',
          shortTitle: 'Viewport Size',
          suggestFilterValues: true,
          isVisible: true,
        },
      ],
      segments: [],
    },
  ],
};
