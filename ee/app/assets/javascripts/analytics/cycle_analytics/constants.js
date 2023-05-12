import { getValueStreamMetrics } from 'ee/api/analytics_api';
import { METRIC_TYPE_SUMMARY, METRIC_TYPE_TIME_SUMMARY } from '~/api/analytics_api';
import { OVERVIEW_STAGE_ID } from '~/analytics/cycle_analytics/constants';
import { __, s__ } from '~/locale';
import { DEFAULT_NULL_SERIES_OPTIONS } from '../shared/constants';

export const TASKS_BY_TYPE_SUBJECT_ISSUE = 'Issue';
export const TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST = 'MergeRequest';
export const TASKS_BY_TYPE_MAX_LABELS = 15;

export const TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS = {
  [TASKS_BY_TYPE_SUBJECT_ISSUE]: __('Issues'),
  [TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST]: __('Merge Requests'),
};

export const TASKS_BY_TYPE_FILTERS = {
  SUBJECT: 'SUBJECT',
  LABEL: 'LABEL',
};

export const DEFAULT_VALUE_STREAM_ID = 'default';

export const FETCH_VALUE_STREAM_DATA = 'fetchValueStreamData';

export const OVERVIEW_STAGE_CONFIG = {
  id: OVERVIEW_STAGE_ID,
  title: __('Overview'),
  icon: 'home',
};

export const METRICS_REQUESTS = [
  {
    endpoint: METRIC_TYPE_TIME_SUMMARY,
    request: getValueStreamMetrics,
    name: __('time summary'),
  },
  {
    endpoint: METRIC_TYPE_SUMMARY,
    request: getValueStreamMetrics,
    name: __('recent activity'),
  },
];

export const DURATION_OVERVIEW_CHART_X_AXIS_DATE_FORMAT = 'd mmm';
export const DURATION_OVERVIEW_CHART_X_AXIS_TOOLTIP_TITLE_DATE_FORMAT = 'd mmm yyyy';
export const DURATION_OVERVIEW_CHART_NO_DATA = s__('CycleAnalytics|No data');
export const DURATION_OVERVIEW_CHART_NO_DATA_LEGEND_ITEM = {
  name: DURATION_OVERVIEW_CHART_NO_DATA,
  ...DEFAULT_NULL_SERIES_OPTIONS.lineStyle,
  disabled: true,
};
export const DURATION_CHART_X_AXIS_TITLE = s__('CycleAnalytics|Date');
export const DURATION_CHART_Y_AXIS_TITLE = s__('CycleAnalytics|Average time to completion (days)');
export const DURATION_CHART_Y_AXIS_TOOLTIP_TITLE = s__('CycleAnalytics|Average time to completion');
export const DURATION_CHART_TOOLTIP_NO_DATA = __('No data available');
export const DURATION_TOTAL_TIME_LABEL = s__('CycleAnalytics|Total time');
export const DURATION_TOTAL_TIME_NO_DATA = s__(
  "CycleAnalytics|There is no data for 'Total time' available. Adjust the current filters.",
);
export const DURATION_TOTAL_TIME_DESCRIPTION = s__(
  'CycleAnalytics|The total time items spent across each value stream stage. Data limited to items completed within this date range.',
);
export const DURATION_STAGE_TIME_LABEL = s__('CycleAnalytics|Stage time: %{title}');
export const DURATION_STAGE_TIME_NO_DATA = s__(
  "CycleAnalytics|There is no data for 'Stage time' available. Adjust the current filters.",
);
export const DURATION_STAGE_TIME_DESCRIPTION = s__(
  'CycleAnalytics|The average time items spent in this stage. Data limited to items completed within this date range.',
);
export const EMPTY_STATE_TITLE = s__(
  'CycleAnalytics|Custom value streams to measure your DevSecOps lifecycle',
);
export const EMPTY_STATE_DESCRIPTION = s__(
  'CycleAnalytics|Create a custom value stream to view metrics about stages specific to your development process. Use your value stream to visualize your DevSecOps lifecycle, determine the velocity of your group, and identify inefficient processes.',
);
export const EMPTY_STATE_ACTION_TEXT = s__('CycleAnalytics|New value stream…');
export const EMPTY_STATE_SECONDARY_TEXT = __('Learn more');
export const EMPTY_STATE_FILTER_ERROR_TITLE = __(
  'Value Stream Analytics can help you determine your team’s velocity',
);
export const EMPTY_STATE_FILTER_ERROR_DESCRIPTION = __(
  'Filter parameters are not valid. Make sure that the end date is after the start date.',
);

export const AGGREGATING_DATA_WARNING_TITLE = s__('CycleAnalytics|Data is collecting and loading.');
export const AGGREGATING_DATA_WARNING_MESSAGE = s__(
  "CycleAnalytics|'%{name}' is collecting the data. This can take a few minutes.",
);
export const AGGREGATING_DATA_WARNING_NEXT_UPDATE = s__(
  'CycleAnalytics|If you have recently upgraded your GitLab license from a tier without this feature, it can take up to 30 minutes for data to collect and display.',
);
export const AGGREGATING_DATA_PRIMARY_ACTION_TEXT = __('Reload page');
export const AGGREGATING_DATA_SECONDARY_ACTION_TEXT = __('Learn more');
