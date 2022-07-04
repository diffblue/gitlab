import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { formatAsPercentage } from '../util';

export * from './shared';

export const medianSeriesName = s__('DORA4Metrics|Median time (last %{days}d)');

export const CHART_TITLE = s__('DORA4Metrics|Change failure rate');

export const areaChartOptions = {
  xAxis: {
    name: s__('DORA4Metrics|Date'),
    type: 'category',
  },
  yAxis: {
    name: s__('DORA4Metrics|Percentage of failed deployments'),
    type: 'value',
    axisLabel: {
      formatter(value) {
        return formatAsPercentage(value);
      },
    },
  },
};

export const chartDescriptionText = s__(
  'DORA4Metrics|Number of incidents divided by the number of deployments to a production environment in the given time period.',
);

export const chartDocumentationHref = helpPagePath('user/analytics/ci_cd_analytics.html', {
  anchor: 'change-failure-rate-charts',
});
