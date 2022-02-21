import { getGroupValueStreamMetrics } from 'ee/api/analytics_api';
import { METRIC_TYPE_SUMMARY, METRIC_TYPE_TIME_SUMMARY } from '~/api/analytics_api';
import { OVERVIEW_STAGE_ID } from '~/cycle_analytics/constants';
import { __, s__ } from '~/locale';

export const EVENTS_LIST_ITEM_LIMIT = 50;

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
    request: getGroupValueStreamMetrics,
    name: __('time summary'),
  },
  {
    endpoint: METRIC_TYPE_SUMMARY,
    request: getGroupValueStreamMetrics,
    name: __('recent activity'),
  },
];

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
