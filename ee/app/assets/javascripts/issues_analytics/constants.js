import { blue400, green400 } from '@gitlab/ui/scss_to_js/scss_variables';
import { s__ } from '~/locale';

export const DEFAULT_MONTHS_BACK = 12;

export const NAMESPACE_PROJECT_TYPE = 'project';

export const NO_DATA_EMPTY_STATE_TYPE = 'noData';
export const NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE = 'noDataWithFilters';

export const ISSUES_OPENED_COUNT_ALIAS = 'issuesOpened';
export const ISSUES_COMPLETED_COUNT_ALIAS = 'issuesClosed';

export const TOTAL_ISSUES_ANALYTICS_CHART_SERIES_NAMES = {
  [ISSUES_OPENED_COUNT_ALIAS]: s__('IssuesAnalytics|Opened'),
  [ISSUES_COMPLETED_COUNT_ALIAS]: s__('IssuesAnalytics|Closed'),
};

export const TOTAL_ISSUES_ANALYTICS_CHART_COLOR_PALETTE = [green400, blue400];
