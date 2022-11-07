import { s__, __ } from '~/locale';
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

export const DORA_METRIC_IDENTIFIERS = [
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
  CHANGE_FAILURE_RATE,
];

export const DASHBOARD_TITLE = __('Executive Dashboard');
export const DASHBOARD_DESCRIPTION = s__('DORA4Metrics|DORA metrics for %{groupName} group');
export const DASHBOARD_NO_DATA = __('No data available');
export const DASHBOARD_LOADING_FAILURE = __('Failed to load');

const NOW = new Date();
const CURRENT_MONTH_START = getStartOfDay(dateAtFirstDayOfMonth(NOW));
const PREVIOUS_MONTH_START = nMonthsBefore(CURRENT_MONTH_START, 1);
const PREVIOUS_MONTH_END = nSecondsBefore(CURRENT_MONTH_START, 1);

export const THIS_MONTH = {
  key: 'thisMonth',
  label: s__('DORA4Metrics|Month to date'),
  start: CURRENT_MONTH_START,
  end: NOW,
};

export const LAST_MONTH = {
  key: 'lastMonth',
  label: monthInWords(nMonthsBefore(NOW, 1)),
  start: PREVIOUS_MONTH_START,
  end: PREVIOUS_MONTH_END,
};

export const TWO_MONTHS_AGO = {
  key: 'twoMonthsAgo',
  label: monthInWords(nMonthsBefore(NOW, 2)),
  start: nMonthsBefore(PREVIOUS_MONTH_START, 1),
  end: nSecondsBefore(PREVIOUS_MONTH_START, 1),
};

export const DASHBOARD_TIME_PERIODS = [THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO];
export const DASHBOARD_TABLE_FIELDS = [
  { key: 'metric', label: __('Metric') },
  ...DASHBOARD_TIME_PERIODS,
];
