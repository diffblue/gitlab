import { s__, __ } from '~/locale';
import { KEY_METRICS, DORA_METRICS } from '~/analytics/shared/constants';

export const UNITS = {
  COUNT: 'COUNT',
  DAYS: 'DAYS',
  PER_DAY: 'PER_DAY',
  PERCENT: 'PERCENT',
};

export const TABLE_METRICS = {
  [DORA_METRICS.DEPLOYMENT_FREQUENCY]: {
    label: s__('DORA4Metrics|Deployment Frequency'),
    units: UNITS.PER_DAY,
  },
  [DORA_METRICS.LEAD_TIME_FOR_CHANGES]: {
    label: s__('DORA4Metrics|Lead Time for Changes'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [DORA_METRICS.TIME_TO_RESTORE_SERVICE]: {
    label: s__('DORA4Metrics|Time to Restore Service'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [DORA_METRICS.CHANGE_FAILURE_RATE]: {
    label: s__('DORA4Metrics|Change Failure Rate'),
    invertTrendColor: true,
    units: UNITS.PERCENT,
  },
  [KEY_METRICS.LEAD_TIME]: {
    label: s__('DORA4Metrics|Lead time'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [KEY_METRICS.CYCLE_TIME]: {
    label: s__('DORA4Metrics|Cycle time'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [KEY_METRICS.ISSUES]: {
    label: s__('DORA4Metrics|New issues'),
    units: UNITS.COUNT,
  },
  [KEY_METRICS.DEPLOYS]: {
    label: s__('DORA4Metrics|Deploys'),
    units: UNITS.COUNT,
  },
};

export const DASHBOARD_TITLE = __('Value Streams Dashboard (Beta)');
export const DASHBOARD_DESCRIPTION_GROUP = s__('DORA4Metrics|Metrics comparison for %{name} group');
export const DASHBOARD_DESCRIPTION_PROJECT = s__(
  'DORA4Metrics|Metrics comparison for %{name} project',
);
export const DASHBOARD_NO_DATA = __('No data available');
export const DASHBOARD_LOADING_FAILURE = __('Failed to load');
export const DASHBOARD_FEEDBACK_INFORMATION = s__(
  'DevopsMetricsDashboard|%{strongStart}Beta feature:%{strongEnd} Leave your thoughts in the %{linkStart}feedback issue%{linkEnd}.',
);
export const DASHBOARD_FEEDBACK_LINK = 'https://gitlab.com/gitlab-org/gitlab/-/issues/381787';

export const CHART_GRADIENT = ['#499767', '#5252B5'];
export const CHART_GRADIENT_INVERTED = [...CHART_GRADIENT].reverse();
export const CHART_LOADING_FAILURE = s__('DORA4Metrics|Failed to load charts');

export const CHART_TOOLTIP_UNITS = {
  [UNITS.COUNT]: undefined,
  [UNITS.DAYS]: __('days'),
  [UNITS.PER_DAY]: __('/day'),
  [UNITS.PERCENT]: '%',
};
