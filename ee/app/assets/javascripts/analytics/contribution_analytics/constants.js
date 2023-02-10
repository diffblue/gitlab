import { __, s__ } from '~/locale';

export const CHART_HEIGHT = 350;
export const INNER_CHART_HEIGHT = 200;
export const CHART_X_AXIS_ROTATE = 45;
export const CHART_X_AXIS_NAME_TOP_PADDING = 55;

export const LEGACY_TABLE_COLUMNS = [
  { name: 'fullname', text: __('Name') },
  { name: 'push', text: __('Pushed') },
  { name: 'issuesCreated', text: __('Opened issues') },
  { name: 'issuesClosed', text: __('Closed issues') },
  { name: 'mergeRequestsCreated', text: __('Opened MRs') },
  { name: 'mergeRequestsApproved', text: __('Approved MRs') },
  { name: 'mergeRequestsMerged', text: __('Merged MRs') },
  { name: 'mergeRequestsClosed', text: __('Closed MRs') },
  { name: 'totalEvents', text: __('Total Contributions') },
];

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
