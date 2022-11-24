import { __ } from '~/locale';

export const CHART_HEIGHT = 350;
export const INNER_CHART_HEIGHT = 200;
export const CHART_X_AXIS_ROTATE = 45;
export const CHART_X_AXIS_NAME_TOP_PADDING = 55;

export const TABLE_COLUMNS = [
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
