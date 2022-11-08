import { THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO } from 'ee/analytics/dashboards/constants';

const mockDoraMetrics = ([
  leadTimeForChanges,
  timeToRestoreService,
  changeFailureRate,
  deploymentFrequency,
]) => ({
  lead_time_for_changes: {
    value: leadTimeForChanges,
    unit: 'days',
    label: 'Lead Time for Changes',
    identifier: 'lead_time_for_changes',
  },
  time_to_restore_service: {
    value: timeToRestoreService,
    unit: 'days',
    label: 'Time to Restore Service',
    identifier: 'time_to_restore_service',
  },
  change_failure_rate: {
    value: changeFailureRate,
    unit: '%',
    label: 'Change Failure Rate',
    identifier: 'change_failure_rate',
  },
  deployment_frequency: {
    value: deploymentFrequency,
    unit: '/day',
    label: 'Deployment Frequency',
    identifier: 'deployment_frequency',
  },
});

export const mockMonthToDate = mockDoraMetrics([0.2, 0.4, 8.54, 19.9]);
export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockDoraMetrics([2.5, 22.32, 5.2, 1.7]);
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockDoraMetrics([3.5, 25.32, 8.2, 0.7]);
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockComparativeTableData = [
  {
    metric: 'Deployment Frequency',
    thisMonth: '19.9/d',
    lastMonth: '1.7/d',
    twoMonthsAgo: '0.7/d',
  },
  {
    metric: 'Lead Time for Changes',
    thisMonth: '0.2 d',
    lastMonth: '2.5 d',
    twoMonthsAgo: '3.5 d',
  },
  {
    metric: 'Time to Restore Service',
    thisMonth: '0.4 d',
    lastMonth: '22.32 d',
    twoMonthsAgo: '25.32 d',
  },
  {
    metric: 'Change Failure Rate',
    thisMonth: '8.54%',
    lastMonth: '5.2%',
    twoMonthsAgo: '8.2%',
  },
];

export const mockMetricsResponse = [
  ...Object.values(mockMonthToDate),
  {
    value: '-',
    unit: 'days',
    label: 'Lead Time',
    identifier: 'lead_time',
  },
  {
    value: '-',
    unit: 'days',
    label: 'Cycle Time',
    identifier: 'cycle_time',
  },
  {
    value: '-',
    label: 'New Issues',
    identifier: 'issues',
    description: 'Number of new issues created.',
  },
  {
    value: '597',
    label: 'Deploys',
    identifier: 'deploys',
  },
];
