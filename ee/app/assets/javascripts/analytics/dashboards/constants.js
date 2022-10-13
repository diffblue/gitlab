import { __ } from '~/locale';
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

export const DASHBOARD_NO_DATA_MESSAGE = __('No data available');
export const DASHBOARD_LOADING_FAILURE_MESSAGE = __('Failed to load');

export const DASHBOARD_COLUMN_TITLE_CHANGE = __('Change');
export const DASHBOARD_COLUMN_TITLE_PREVIOUS = __('30 Before that');
export const DASHBOARD_COLUMN_TITLE_CURRENT = __('Last 30 Days');
export const DASHBOARD_COLUMN_TITLE_METRIC = __('Value');

export const COMPARISON_INTERVAL_IN_DAYS = 30;

export const DASHBOARD_TABLE_FIELDS = [
  { key: 'metric', label: DASHBOARD_COLUMN_TITLE_METRIC },
  { key: 'current', label: DASHBOARD_COLUMN_TITLE_CURRENT },
  { key: 'previous', label: DASHBOARD_COLUMN_TITLE_PREVIOUS },
  { key: 'change', label: DASHBOARD_COLUMN_TITLE_CHANGE },
];
