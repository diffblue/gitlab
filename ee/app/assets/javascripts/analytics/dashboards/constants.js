import { s__, __ } from '~/locale';
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
