import { s__, __ } from '~/locale';
import { thWidthPercent } from '~/lib/utils/table_utility';
import {
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nSecondsBefore,
  nMonthsBefore,
  monthInWords,
} from '~/lib/utils/datetime_utility';
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

const NOW = new Date();
const CURRENT_MONTH_START = getStartOfDay(dateAtFirstDayOfMonth(NOW));
const PREVIOUS_MONTH_START = nMonthsBefore(CURRENT_MONTH_START, 1);
const PREVIOUS_MONTH_END = nSecondsBefore(CURRENT_MONTH_START, 1);

export const THIS_MONTH = {
  key: 'thisMonth',
  label: s__('DORA4Metrics|Month to date'),
  start: CURRENT_MONTH_START,
  end: NOW,
  thClass: thWidthPercent(20),
};

export const LAST_MONTH = {
  key: 'lastMonth',
  label: monthInWords(nMonthsBefore(NOW, 1)),
  start: PREVIOUS_MONTH_START,
  end: PREVIOUS_MONTH_END,
  thClass: thWidthPercent(20),
};

export const TWO_MONTHS_AGO = {
  key: 'twoMonthsAgo',
  label: monthInWords(nMonthsBefore(NOW, 2)),
  start: nMonthsBefore(PREVIOUS_MONTH_START, 1),
  end: nSecondsBefore(PREVIOUS_MONTH_START, 1),
  thClass: thWidthPercent(20),
};

export const THREE_MONTHS_AGO = {
  key: 'threeMonthsAgo',
  label: monthInWords(nMonthsBefore(NOW, 3)),
  start: nMonthsBefore(PREVIOUS_MONTH_START, 2),
  end: nSecondsBefore(nMonthsBefore(PREVIOUS_MONTH_START, 1), 1),
};

export const DASHBOARD_TIME_PERIODS = [THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO, THREE_MONTHS_AGO];

// Generate the chart time periods, starting with the oldest first:
// 5 months ago -> 4 months ago -> etc.
export const CHART_TIME_PERIODS = [5, 4, 3, 2, 1, 0].map((monthsAgo) => ({
  end: monthsAgo === 0 ? NOW : nMonthsBefore(NOW, monthsAgo),
  start: nMonthsBefore(NOW, monthsAgo + 1),
}));

export const DASHBOARD_TABLE_FIELDS = [
  {
    key: 'metric',
    label: __('Metric'),
    thClass: thWidthPercent(25),
  },
  ...DASHBOARD_TIME_PERIODS.slice(0, -1),
  {
    key: 'chart',
    label: s__('DORA4Metrics|Past 6 Months'),
    start: nMonthsBefore(NOW, 6),
    end: NOW,
    thClass: thWidthPercent(15),
    tdClass: 'gl-py-2! gl-pointer-events-none',
  },
];

export const CHART_TOOLTIP_UNITS = {
  [UNITS.COUNT]: undefined,
  [UNITS.DAYS]: __('days'),
  [UNITS.PER_DAY]: __('/day'),
  [UNITS.PERCENT]: '%',
};
