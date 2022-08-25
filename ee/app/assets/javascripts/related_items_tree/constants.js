import { s__, __ } from '~/locale';

export const ChildType = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  Epic: 'Epic',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  Issue: 'Issue',
};

export const ChildState = {
  Open: 'opened',
  Closed: 'closed',
};

export const idProp = {
  Epic: 'id',
  Issue: 'epicIssueId',
};

export const relativePositions = {
  Before: 'before',
  After: 'after',
};

export const RemoveItemModalProps = {
  Epic: {
    title: s__('Epics|Remove epic'),
    body: s__(
      'Epics|This will also remove any descendents of %{bStart}%{targetEpicTitle}%{bEnd} from %{bStart}%{parentEpicTitle}%{bEnd}. Are you sure?',
    ),
  },
  Issue: {
    title: s__('Epics|Remove issue'),
    body: s__(
      'Epics|Are you sure you want to remove %{bStart}%{targetIssueTitle}%{bEnd} from %{bStart}%{parentEpicTitle}%{bEnd}?',
    ),
  },
};

export const OVERFLOW_AFTER = 5;

export const SEARCH_DEBOUNCE = 500;

export const EXPAND_DELAY = 1000;

export const itemRemoveModalId = 'item-remove-confirmation';

export const treeItemChevronBtnClassName = 'btn-tree-item-chevron';

export const issueHealthStatus = {
  atRisk: __('At risk'),
  onTrack: __('On track'),
  needsAttention: __('Needs attention'),
};

export const issueHealthStatusCSSMapping = {
  atRisk: 'status-at-risk',
  onTrack: 'status-on-track',
  needsAttention: 'status-needs-attention',
};

export const trackingAddedIssue = 'g_project_management_users_epic_issue_added_from_epic';

export const SNOWPLOW_EPIC_ACTIVITY = {
  CATEGORY: 'epics_action',
  ACTION: 'perform_epics_action',
  LABEL: 'redis_hll_counters.epics_usage.epics_usage_total_unique_counts_monthly',
};

export const ITEM_TABS = {
  TREE: 'tree',
  ROADMAP: 'roadmap',
};

export const i18n = {
  permissionAlert: __('Counts reflect children you may not have access to.'),
};
