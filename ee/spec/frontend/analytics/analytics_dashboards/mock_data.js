import { TEST_HOST } from 'spec/test_constants';

export const TEST_JITSU_KEY = 'gid://gitlab/Project/2';

export const TEST_COLLECTOR_HOST = TEST_HOST;

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

export const mockCountResultSet = (count) => ({
  rawData: () => [
    {
      'TrackedEvents.count': count,
    },
  ],
});
export const mockFilters = {
  startDate: new Date('2015-01-01'),
  endDate: new Date('2016-01-01'),
};
