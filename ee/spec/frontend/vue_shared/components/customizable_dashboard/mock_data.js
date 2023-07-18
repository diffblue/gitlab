import { __ } from '~/locale';

const cubeLineChart = {
  type: 'LineChart',
  slug: 'cube_line_chart',
  title: 'Cube line chart',
  data: {
    type: 'cube_analytics',
    query: {
      users: {
        measures: ['SnowplowTrackedEvents.count'],
        dimensions: ['SnowplowTrackedEvents.eventType'],
      },
    },
  },
  options: {
    xAxis: {
      name: 'Time',
      type: 'time',
    },
    yAxis: {
      name: 'Counts',
    },
  },
};

export const dashboard = {
  id: 'analytics_overview',
  slug: 'analytics_overview',
  title: 'Analytics Overview',
  userDefined: true,
  panels: [
    {
      id: 1,
      title: __('Test A'),
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: null,
    },
    {
      id: 2,
      title: __('Test B'),
      gridAttributes: { width: 2, height: 4 },
      visualization: cubeLineChart,
      queryOverrides: {
        limit: 200,
      },
    },
  ],
};

export const builtinDashboard = {
  title: 'Analytics Overview',
  panels: [
    {
      id: 1,
      title: __('Test A'),
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: {},
    },
  ],
};

export const mockDateRangeFilterChangePayload = {
  startDate: new Date('2016-01-01'),
  endDate: new Date('2016-02-01'),
  dateRangeOption: 'foo',
};
