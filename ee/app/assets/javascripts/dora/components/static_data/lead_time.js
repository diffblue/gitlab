import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export * from './shared';

export const CHART_TITLE = s__('DORA4Metrics|Lead time for changes');

export const medianSeriesTitle = s__('DORA4Metrics|Median (last %{days}d)');

export const areaChartOptions = {
  xAxis: {
    name: s__('DORA4Metrics|Date'),
    type: 'category',
  },
  yAxis: {
    name: s__('DORA4Metrics|Days from merge to deploy'),
    type: 'value',
    minInterval: 1,
    axisLabel: {
      formatter(seconds) {
        // 86400 = the number of seconds in 1 day
        return (seconds / 86400).toFixed(1);
      },
    },
  },
};

export const chartDescriptionText = s__(
  'DORA4Metrics|The chart displays the median time between a merge request being merged and deployed to production environment(s) that are based on the %{linkStart}deployment_tier%{linkEnd} value.',
);

export const chartDocumentationHref = helpPagePath('user/analytics/ci_cd_analytics.html', {
  anchor: 'lead-time-charts',
});
