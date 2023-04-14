import { s__, __ } from '~/locale';

export const ParentType = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  Epic: 'Epic',
};

export const ChildType = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  Epic: 'Epic',
  EpicWithChildren: 'EpicWithChildren',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  Issue: 'Issue',
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
      'Epics|Are you sure you want to remove %{bStart}%{targetEpicTitle}%{bEnd} from %{bStart}%{parentEpicTitle}%{bEnd}?',
    ),
  },
  EpicWithChildren: {
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

export const issueHealthStatusVariantMapping = {
  atRisk: 'danger',
  onTrack: 'success',
  needsAttention: 'warning',
};

export const trackingAddedIssue = 'g_project_management_users_epic_issue_added_from_epic';

export const SNOWPLOW_EPIC_ACTIVITY = {
  CATEGORY: 'epics_action',
  ACTION: 'perform_epics_action',
  LABEL: 'redis_hll_counters.epics_usage.epics_usage_total_unique_counts_monthly',
};

export const ROADMAP_ACTIVITY_TRACK_ACTION_LABEL = 'roadmap_tab_click';
export const ROADMAP_ACTIVITY_TRACK_LABEL = 'roadmap';

export const ITEM_TABS = {
  TREE: 'tree',
  ROADMAP: 'roadmap',
};

export const i18n = {
  permissionAlert: __('Counts reflect children you may not have access to.'),
};

export const i18nConfidentialParent = {
  [ParentType.Epic]: __(
    'The parent epic is confidential and can only contain confidential epics and issues',
  ),
};

export const treeTitle = {
  [ParentType.Epic]: __('Issues'),
};

export const EPIC_CREATE_ERROR_MESSAGE = s__(
  'Epics|Something went wrong while creating child epics.',
);
