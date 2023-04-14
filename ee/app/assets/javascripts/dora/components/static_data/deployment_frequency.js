import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export * from './shared';

export const averageSeriesName = s__('DORA4Metrics|Average (last %{days}d)');

export const CHART_TITLE = s__('DORA4Metrics|Deployment frequency');

export const areaChartOptions = {
  xAxis: {
    name: s__('DORA4Metrics|Date'),
    type: 'category',
  },
  yAxis: {
    name: s__('DORA4Metrics|Predicted number of deployments'),
    type: 'value',
    minInterval: 1,
  },
};

export const chartDescriptionText = s__(
  'DORA4Metrics|The chart displays the frequency of deployments to production environment(s) that are based on the %{linkStart}deployment_tier%{linkEnd} value.',
);

export const chartDocumentationHref = helpPagePath('user/analytics/ci_cd_analytics.html', {
  anchor: 'deployment-frequency-charts',
});
