import { s__ } from '~/locale';

export const CHART_HEIGHT = 350;
export const INNER_CHART_HEIGHT = 200;
export const CHART_X_AXIS_ROTATE = 45;
export const CHART_X_AXIS_NAME_TOP_PADDING = 55;
export const MAX_DAYS_PER_REQUEST = 7;

export const TABLE_COLUMNS = [
  { key: 'user', label: s__('ContributionAnalytics|Name') },
  { key: 'repoPushed', label: s__('ContributionAnalytics|Pushed') },
  { key: 'issuesCreated', label: s__('ContributionAnalytics|Opened issues') },
  { key: 'issuesClosed', label: s__('ContributionAnalytics|Closed issues') },
  { key: 'mergeRequestsCreated', label: s__('ContributionAnalytics|Opened MRs') },
  { key: 'mergeRequestsApproved', label: s__('ContributionAnalytics|Approved MRs') },
  { key: 'mergeRequestsMerged', label: s__('ContributionAnalytics|Merged MRs') },
  { key: 'mergeRequestsClosed', label: s__('ContributionAnalytics|Closed MRs') },
  { key: 'totalEvents', label: s__('ContributionAnalytics|Total Contributions') },
].map((col) => ({
  ...col,
  sortable: true,
  thClass: 'gl-vertical-align-middle!',
}));
