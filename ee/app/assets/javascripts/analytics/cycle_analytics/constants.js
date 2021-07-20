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

export const OVERVIEW_METRICS = {
  TIME_SUMMARY: 'TIME_SUMMARY',
  RECENT_ACTIVITY: 'RECENT_ACTIVITY',
};

export const FETCH_VALUE_STREAM_DATA = 'fetchValueStreamData';

export const OVERVIEW_STAGE_CONFIG = {
  id: OVERVIEW_STAGE_ID,
  slug: OVERVIEW_STAGE_ID,
  title: __('Overview'),
  icon: 'home',
};

export const METRICS_POPOVER_CONTENT = {
  'lead-time': {
    description: s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
  },
  'cycle-time': {
    description: s__(
      'ValueStreamAnalytics|Median time from issue first merge request created to issue closed.',
    ),
  },
  'new-issues': { description: s__('ValueStreamAnalytics|Number of new issues created.') },
  deploys: { description: s__('ValueStreamAnalytics|Total number of deploys to production.') },
  'deployment-frequency': {
    description: s__('ValueStreamAnalytics|Average number of deployments to production per day.'),
  },
};
