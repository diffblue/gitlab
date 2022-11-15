import {
  THIS_MONTH,
  LAST_MONTH,
  TWO_MONTHS_AGO,
  THREE_MONTHS_AGO,
} from 'ee/analytics/dashboards/constants';

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

export const mockMonthToDate = mockDoraMetrics([5.1, 4, 8, 0]);
export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockDoraMetrics([3.6, 20, 4, 2]);
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockDoraMetrics([9.2, 32, 8, 4]);
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockThreeMonthsAgo = mockDoraMetrics([20.1, 32, 8, 2]);
export const mockThreeMonthsAgoTimePeriod = { ...THREE_MONTHS_AGO, ...mockThreeMonthsAgo };
export const mockThreeMonthsAgoApiResponse = Object.values(mockThreeMonthsAgo);

export const mockComparativeTableData = [
  {
    metric: { value: 'Deployment Frequency' },
    thisMonth: {
      value: '0.0/d',
      change: 0,
    },
    lastMonth: {
      value: '2.0/d',
      change: -0.5,
    },
    twoMonthsAgo: {
      value: '4.0/d',
      change: 1,
    },
  },
  {
    metric: { value: 'Lead Time for Changes' },
    thisMonth: {
      value: '5.1 d',
      change: 0.4166666666666665,
    },
    lastMonth: {
      value: '3.6 d',
      change: -0.6086956521739131,
    },
    twoMonthsAgo: {
      value: '9.2 d',
      change: -0.5422885572139304,
    },
  },
  {
    metric: { value: 'Time to Restore Service' },
    thisMonth: {
      value: '4.0 d',
      change: -0.8,
    },
    lastMonth: {
      value: '20.0 d',
      change: -0.375,
    },
    twoMonthsAgo: {
      value: '32.0 d',
      change: 0,
    },
  },
  {
    metric: { value: 'Change Failure Rate' },
    thisMonth: {
      value: '8.00%',
      change: 1,
    },
    lastMonth: {
      value: '4.00%',
      change: -0.5,
    },
    twoMonthsAgo: {
      value: '8.00%',
      change: 0,
    },
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
