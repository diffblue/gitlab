import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { days, percentHundred } from '~/lib/utils/unit_format';
import { thWidthPercent } from '~/lib/utils/table_utility';
import {
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nSecondsBefore,
  nMonthsBefore,
  monthInWords,
} from '~/lib/utils/datetime_utility';
import {
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
  CHANGE_FAILURE_RATE,
} from 'ee/api/dora_api';
import {
  LEAD_TIME_METRIC_TYPE,
  CYCLE_TIME_METRIC_TYPE,
  ISSUES_METRIC_TYPE,
  DEPLOYS_METRIC_TYPE,
} from '~/api/analytics_api';

const UNITS = {
  PER_DAY: {
    chartUnits: __('/day'),
    formatValue: (value) => days(value, 1, { unitSeparator: '/' }),
  },
  DAYS: {
    chartUnits: __('days'),
    formatValue: (value) => days(value, 1, { unitSeparator: ' ' }),
  },
  PERCENT: {
    chartUnits: '%',
    formatValue: (value) => percentHundred(value, 2),
  },
};

export const DORA_METRICS = {
  [DEPLOYMENT_FREQUENCY_METRIC_TYPE]: {
    label: s__('DORA4Metrics|Deployment Frequency'),
    ...UNITS.PER_DAY,
  },
  [LEAD_TIME_FOR_CHANGES]: {
    label: s__('DORA4Metrics|Lead Time for Changes'),
    invertTrendColor: true,
    ...UNITS.DAYS,
  },
  [TIME_TO_RESTORE_SERVICE]: {
    label: s__('DORA4Metrics|Time to Restore Service'),
    invertTrendColor: true,
    ...UNITS.DAYS,
  },
  [CHANGE_FAILURE_RATE]: {
    label: s__('DORA4Metrics|Change Failure Rate'),
    invertTrendColor: true,
    ...UNITS.PERCENT,
  },
  [LEAD_TIME_METRIC_TYPE]: {
    label: s__('DORA4Metrics|Lead time'),
    invertTrendColor: true,
    ...UNITS.DAYS,
  },
  [CYCLE_TIME_METRIC_TYPE]: {
    label: s__('DORA4Metrics|Cycle time'),
    invertTrendColor: true,
    ...UNITS.DAYS,
  },
  [ISSUES_METRIC_TYPE]: {
    label: s__('DORA4Metrics|New issues'),
    formatValue: (value) => value,
  },
  [DEPLOYS_METRIC_TYPE]: {
    label: s__('DORA4Metrics|Deploys'),
    formatValue: (value) => value,
  },
};

export const DASHBOARD_TITLE = __('DevOps metrics comparison (Beta)');
export const DASHBOARD_DESCRIPTION_GROUP = s__('DORA4Metrics|DORA metrics for %{name} group');
export const DASHBOARD_DESCRIPTION_PROJECT = s__('DORA4Metrics|DORA metrics for %{name} project');
export const DASHBOARD_NO_DATA = __('No data available');
export const DASHBOARD_LOADING_FAILURE = __('Failed to load');
export const DASHBOARD_FEEDBACK_INFORMATION = s__(
  'DevopsMetricsDashboard|%{strongStart}Beta feature:%{strongEnd} Leave your thoughts in the %{linkStart}feedback issue%{linkEnd}.',
);
export const DASHBOARD_FEEDBACK_LINK = 'https://gitlab.com/gitlab-org/gitlab/-/issues/381787';

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
  },
];

export const METRIC_TOOLTIPS = {
  [DEPLOYMENT_FREQUENCY_METRIC_TYPE]: {
    description: s__(
      'DORA4Metrics|Average number of deployments to production per day. This metric measures how often value is delivered to end users.',
    ),
    groupLink: '-/analytics/ci_cd?tab=deployment-frequency',
    projectLink: '-/pipelines/charts?chart=deployment-frequency',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'deployment-frequency' }),
  },
  [LEAD_TIME_FOR_CHANGES]: {
    description: s__(
      'DORA4Metrics|The time to successfully deliver a commit into production. This metric reflects the efficiency of CI/CD pipelines.',
    ),
    groupLink: '-/analytics/ci_cd?tab=lead-time',
    projectLink: '-/pipelines/charts?chart=lead-time',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'lead-time-for-changes' }),
  },
  [TIME_TO_RESTORE_SERVICE]: {
    description: s__(
      'DORA4Metrics|The time it takes an organization to recover from a failure in production.',
    ),
    groupLink: '-/analytics/ci_cd?tab=time-to-restore-service',
    projectLink: '-/pipelines/charts?chart=time-to-restore-service',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'time-to-restore-service' }),
  },
  [CHANGE_FAILURE_RATE]: {
    description: s__(
      'DORA4Metrics|Percentage of deployments that cause an incident in production.',
    ),
    groupLink: '-/analytics/ci_cd?tab=change-failure-rate',
    projectLink: '-/pipelines/charts?chart=change-failure-rate',
    docsLink: helpPagePath('user/analytics/dora_metrics', { anchor: 'change-failure-rate' }),
  },
  [LEAD_TIME_METRIC_TYPE]: {
    description: s__('DORA4Metrics|Median time from issue created to issue closed.'),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [CYCLE_TIME_METRIC_TYPE]: {
    description: s__(
      "DORA4Metrics|Median time from the earliest commit of a linked issue's merge request to when that issue is closed.",
    ),
    groupLink: '-/analytics/value_stream_analytics',
    projectLink: '-/value_stream_analytics',
    docsLink: helpPagePath('user/analytics/value_stream_analytics', {
      anchor: 'view-the-lead-time-and-cycle-time-for-issues',
    }),
  },
  [ISSUES_METRIC_TYPE]: {
    description: s__('DORA4Metrics|Number of new issues created.'),
    groupLink: '-/issues_analytics',
    projectLink: '-/analytics/issues_analytics',
    docsLink: helpPagePath('user/analytics/issue_analytics'),
  },
  [DEPLOYS_METRIC_TYPE]: {
    description: s__('DORA4Metrics|Total number of deploys to production.'),
    groupLink: '-/analytics/productivity_analytics',
    projectLink: '-/analytics/merge_request_analytics',
    docsLink: helpPagePath('user/analytics/merge_request_analytics'),
  },
};
