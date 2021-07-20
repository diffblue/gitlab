import { __ } from '~/locale';

const COLUMNS = [
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

export default COLUMNS;
