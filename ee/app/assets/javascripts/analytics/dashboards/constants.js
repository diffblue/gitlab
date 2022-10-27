import { s__, __ } from '~/locale';
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

const DASHBOARD_COLUMN_TITLE_CHANGE = __('Change');
const DASHBOARD_COLUMN_TITLE_PREVIOUS = s__('DORA4Metrics|30 days before that');
const DASHBOARD_COLUMN_TITLE_CURRENT = s__('DORA4Metrics|Last 30 days');
const DASHBOARD_COLUMN_TITLE_METRIC = __('Metric');

export const COMPARISON_INTERVAL_IN_DAYS = 30;

export const DASHBOARD_TABLE_FIELDS = [
  { key: 'metric', label: DASHBOARD_COLUMN_TITLE_METRIC },
  { key: 'current', label: DASHBOARD_COLUMN_TITLE_CURRENT },
  { key: 'previous', label: DASHBOARD_COLUMN_TITLE_PREVIOUS },
  { key: 'change', label: DASHBOARD_COLUMN_TITLE_CHANGE },
];
