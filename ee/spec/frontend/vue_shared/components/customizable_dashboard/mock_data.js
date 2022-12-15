import { __ } from '~/locale';

const cubeLineChart = {
  type: 'LineChart',
  data: {
    type: 'cube_analytics',
    query: {
      users: {
        measures: ['Jitsu.count'],
        dimensions: ['Jitsu.eventType'],
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
  title: 'Analytics Overview',
  widgets: [
    {
      title: __('Test A'),
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: {},
    },
    {
      title: __('Test B'),
      gridAttributes: { width: 2, height: 4 },
      visualization: cubeLineChart,
      queryOverrides: {},
    },
  ],
};
