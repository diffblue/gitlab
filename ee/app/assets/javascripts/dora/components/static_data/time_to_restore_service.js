import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { secondsToDays } from '../util';

export * from './shared';

export const medianSeriesName = s__('DORA4Metrics|Median time (last %{days}d)');

export const CHART_TITLE = s__('DORA4Metrics|Time to restore service');

export const areaChartOptions = {
  xAxis: {
    name: s__('DORA4Metrics|Date'),
    type: 'category',
  },
  yAxis: {
    name: s__('DORA4Metrics|Days for an open incident'),
    type: 'value',
    minInterval: 1,
    axisLabel: {
      formatter(seconds) {
        return secondsToDays(seconds);
      },
    },
  },
};

export const chartDescriptionText = s__(
  'DORA4Metrics|Median time an incident was open in a production environment over the given time period.',
);

export const chartDocumentationHref = helpPagePath('user/analytics/ci_cd_analytics.html', {
  anchor: 'time-to-restore-service-charts',
});
