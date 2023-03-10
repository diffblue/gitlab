import { __ } from '~/locale';

const cubeLineChart = {
  type: 'LineChart',
  data: {
    type: 'cube_analytics',
    query: {
      users: {
        measures: ['TrackedEvents.count'],
        dimensions: ['TrackedEvents.eventType'],
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
  title: 'Analytics Overview',
  panels: [
    {
      id: 1,
      title: __('Test A'),
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: {},
    },
    {
      id: 2,
      title: __('Test B'),
      gridAttributes: { width: 2, height: 4 },
      visualization: cubeLineChart,
      queryOverrides: {},
    },
  ],
};

export const builtinDashboard = {
  title: 'Analytics Overview',
  builtin: true,
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
