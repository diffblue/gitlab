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
