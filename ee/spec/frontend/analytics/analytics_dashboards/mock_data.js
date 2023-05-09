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

export const TEST_CUSTOM_DASHBOARDS_LIST = [
  {
    file_name: 'product_analytics',
    lock_label: null,
  },
  {
    file_name: 'new_dashboard.yml',
    lock_label: null,
  },
];

export const TEST_CUSTOM_DASHBOARD = {
  id: 'new_dashboard',
  title: 'New dashboard',
  panels: [
    {
      id: 1,
      visualization: 'page_views_per_day',
      visualizationType: 'yml',
      gridAttributes: {
        yPos: 0,
        xPos: 0,
        width: 7,
        height: 6,
      },
      options: {},
    },
  ],
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

export const mockFilters = {
  startDate: new Date('2015-01-01'),
  endDate: new Date('2016-01-01'),
};

export const mockMetaData = {
  cubes: [
    {
      name: 'TrackedEvents',
      title: 'TrackedEvents',
      measures: [
        {
          name: 'TrackedEvents.count',
          title: 'TrackedEvents Count',
          shortTitle: 'Count',
          cumulativeTotal: false,
          cumulative: false,
          type: 'number',
          aggType: 'count',
          drillMembers: [
            'TrackedEvents.eventnCtxEventId',
            'TrackedEvents.idsAjsAnonymousId',
            'TrackedEvents.pageTitle',
            'TrackedEvents.userAnonymousId',
            'TrackedEvents.userHashedAnonymousId',
          ],
          drillMembersGrouped: {
            measures: [],
            dimensions: [
              'TrackedEvents.eventnCtxEventId',
              'TrackedEvents.idsAjsAnonymousId',
              'TrackedEvents.pageTitle',
              'TrackedEvents.userAnonymousId',
              'TrackedEvents.userHashedAnonymousId',
            ],
          },
          isVisible: true,
        },
      ],
      dimensions: [
        {
          name: 'TrackedEvents.apiKey',
          title: 'TrackedEvents Api Key',
          type: 'string',
          shortTitle: 'Api Key',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.docEncoding',
          title: 'TrackedEvents Doc Encoding',
          type: 'string',
          shortTitle: 'Doc Encoding',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.docHost',
          title: 'TrackedEvents Doc Host',
          type: 'string',
          shortTitle: 'Doc Host',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.docPath',
          title: 'TrackedEvents Doc Path',
          type: 'string',
          shortTitle: 'Doc Path',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.docSearch',
          title: 'TrackedEvents Doc Search',
          type: 'string',
          shortTitle: 'Doc Search',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.eventType',
          title: 'TrackedEvents Event Type',
          type: 'string',
          shortTitle: 'Event Type',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.eventnCtxEventId',
          title: 'TrackedEvents Eventn Ctx Event Id',
          type: 'string',
          shortTitle: 'Eventn Ctx Event Id',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.idsAjsAnonymousId',
          title: 'TrackedEvents Ids Ajs Anonymous Id',
          type: 'string',
          shortTitle: 'Ids Ajs Anonymous Id',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.localTzOffset',
          title: 'TrackedEvents Local Tz Offset',
          type: 'string',
          shortTitle: 'Local Tz Offset',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.pageTitle',
          title: 'TrackedEvents Page Title',
          type: 'string',
          shortTitle: 'Page Title',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.parsedUaOsFamily',
          title: 'TrackedEvents Parsed Ua Os Family',
          type: 'string',
          shortTitle: 'Parsed Ua Os Family',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.parsedUaOsVersion',
          title: 'TrackedEvents Parsed Ua Os Version',
          type: 'string',
          shortTitle: 'Parsed Ua Os Version',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.parsedUaUaFamily',
          title: 'TrackedEvents Parsed Ua Ua Family',
          type: 'string',
          shortTitle: 'Parsed Ua Ua Family',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.parsedUaUaVersion',
          title: 'TrackedEvents Parsed Ua Ua Version',
          type: 'string',
          shortTitle: 'Parsed Ua Ua Version',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.referer',
          title: 'TrackedEvents Referer',
          type: 'string',
          shortTitle: 'Referer',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.screenResolution',
          title: 'TrackedEvents Screen Resolution',
          type: 'string',
          shortTitle: 'Screen Resolution',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.sourceIp',
          title: 'TrackedEvents Source Ip',
          type: 'string',
          shortTitle: 'Source Ip',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.src',
          title: 'TrackedEvents Src',
          type: 'string',
          shortTitle: 'Src',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.url',
          title: 'TrackedEvents Url',
          type: 'string',
          shortTitle: 'Url',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.userAgent',
          title: 'TrackedEvents User Agent',
          type: 'string',
          shortTitle: 'User Agent',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.userAnonymousId',
          title: 'TrackedEvents User Anonymous Id',
          type: 'string',
          shortTitle: 'User Anonymous Id',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.userHashedAnonymousId',
          title: 'TrackedEvents User Hashed Anonymous Id',
          type: 'string',
          shortTitle: 'User Hashed Anonymous Id',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.userLanguage',
          title: 'TrackedEvents User Language',
          type: 'string',
          shortTitle: 'User Language',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.vpSize',
          title: 'TrackedEvents Vp Size',
          type: 'string',
          shortTitle: 'Vp Size',
          suggestFilterValues: true,
          isVisible: true,
        },
        {
          name: 'TrackedEvents.utcTime',
          title: 'TrackedEvents Utc Time',
          type: 'time',
          shortTitle: 'Utc Time',
          suggestFilterValues: true,
          isVisible: true,
        },
      ],
      segments: [],
    },
  ],
};
