import { __ } from '~/locale';

export function getPanelOptions(visualizationType, hasTimeDimension) {
  switch (visualizationType) {
    case 'LineChart':
      return {
        xAxis: {
          name: __('Time'),
          type: 'time',
        },
        yAxis: {
          name: __('Counts'),
        },
      };
    case 'ColumnChart':
      return {
        xAxis: hasTimeDimension
          ? { name: __('Time'), type: 'time' }
          : {
              name: __('Dimension'),
              type: 'category',
            },
        yAxis: {
          name: __('Counts'),
        },
      };
    default:
      return {};
  }
}
