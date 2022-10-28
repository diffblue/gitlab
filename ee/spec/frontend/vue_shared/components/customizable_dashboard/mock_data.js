import { __ } from '~/locale';

export const dashboard = {
  title: 'Analytics Overview',
  widgets: [
    {
      component: 'CubeLineChart',
      title: __('Test A'),
      gridAttributes: { size: { width: 3, height: 3 } },
      customizations: {},
      chartOptions: {},
      data: {},
    },
    {
      component: 'CubeLineChart',
      title: __('Test B'),
      gridAttributes: { size: { width: 2, height: 4 } },
      customizations: {},
      chartOptions: {},
      data: {},
    },
  ],
};
