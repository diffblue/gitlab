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
  leadTime,
  cycleTime,
  issues,
  deploys,
]) => ({
  lead_time_for_changes: {
    value: leadTimeForChanges,
    label: 'Lead Time for Changes',
    identifier: 'lead_time_for_changes',
  },
  time_to_restore_service: {
    value: timeToRestoreService,
    label: 'Time to Restore Service',
    identifier: 'time_to_restore_service',
  },
  change_failure_rate: {
    value: changeFailureRate,
    label: 'Change Failure Rate',
    identifier: 'change_failure_rate',
  },
  deployment_frequency: {
    value: deploymentFrequency,
    label: 'Deployment Frequency',
    identifier: 'deployment_frequency',
  },
  lead_time: {
    value: leadTime,
    label: 'Lead Time',
    identifier: 'lead_time',
  },
  cycle_time: {
    value: cycleTime,
    label: 'Cycle Time',
    identifier: 'cycle_time',
  },
  issues: {
    value: issues,
    label: 'New Issues',
    identifier: 'issues',
  },
  deploys: {
    value: deploys,
    label: 'Deploys',
    identifier: 'deploys',
  },
});

export const mockMonthToDate = mockDoraMetrics([5.1, 4, 8, 0, 2, 4, 6, 8]);
export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockDoraMetrics([3.6, 20, 4, 2, 4, '-', 12, 16]);
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockDoraMetrics([9.2, 32, 8, 4, 2, '-', 6, 8]);
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockThreeMonthsAgo = mockDoraMetrics([20.1, 32, 8, 2, 4, 8, 12, 16]);
export const mockThreeMonthsAgoTimePeriod = { ...THREE_MONTHS_AGO, ...mockThreeMonthsAgo };
export const mockThreeMonthsAgoApiResponse = Object.values(mockThreeMonthsAgo);

export const mockComparativeTableData = [
  {
    metric: { value: 'Deployment Frequency' },
    thisMonth: {
      value: '0.0/d',
      change: 0,
      invertTrendColor: undefined,
    },
    lastMonth: {
      value: '2.0/d',
      change: -0.5,
      invertTrendColor: undefined,
    },
    twoMonthsAgo: {
      value: '4.0/d',
      change: 1,
      invertTrendColor: undefined,
    },
  },
  {
    metric: { value: 'Lead Time for Changes' },
    thisMonth: {
      value: '5.1 d',
      change: 0.4166666666666665,
      invertTrendColor: true,
    },
    lastMonth: {
      value: '3.6 d',
      change: -0.6086956521739131,
      invertTrendColor: true,
    },
    twoMonthsAgo: {
      value: '9.2 d',
      change: -0.5422885572139304,
      invertTrendColor: true,
    },
  },
  {
    metric: { value: 'Time to Restore Service' },
    thisMonth: {
      value: '4.0 d',
      change: -0.8,
      invertTrendColor: true,
    },
    lastMonth: {
      value: '20.0 d',
      change: -0.375,
      invertTrendColor: true,
    },
    twoMonthsAgo: {
      value: '32.0 d',
      change: 0,
      invertTrendColor: true,
    },
  },
  {
    metric: { value: 'Change Failure Rate' },
    thisMonth: {
      value: '8.00%',
      change: 1,
      invertTrendColor: true,
    },
    lastMonth: {
      value: '4.00%',
      change: -0.5,
      invertTrendColor: true,
    },
    twoMonthsAgo: {
      value: '8.00%',
      change: 0,
      invertTrendColor: true,
    },
  },
  {
    metric: { value: 'Lead time' },
    lastMonth: {
      change: 1,
      value: '4.0 d',
      invertTrendColor: true,
    },
    thisMonth: {
      change: -0.5,
      value: '2.0 d',
      invertTrendColor: true,
    },
    twoMonthsAgo: {
      change: -0.5,
      value: '2.0 d',
      invertTrendColor: true,
    },
  },
  {
    metric: { value: 'Cycle time' },
    lastMonth: {
      change: 0,
      value: '-',
      invertTrendColor: true,
    },
    thisMonth: {
      change: 0,
      value: '4.0 d',
      invertTrendColor: true,
    },
    twoMonthsAgo: {
      change: 0,
      value: '-',
      invertTrendColor: true,
    },
  },
  {
    metric: { value: 'New issues' },
    lastMonth: {
      change: 1,
      value: 12,
      invertTrendColor: undefined,
    },
    thisMonth: {
      change: -0.5,
      value: 6,
      invertTrendColor: undefined,
    },
    twoMonthsAgo: {
      change: -0.5,
      value: 6,
      invertTrendColor: undefined,
    },
  },
  {
    metric: { value: 'Deploys' },
    lastMonth: {
      change: 1,
      value: 16,
      invertTrendColor: undefined,
    },
    thisMonth: {
      change: -0.5,
      value: 8,
      invertTrendColor: undefined,
    },
    twoMonthsAgo: {
      change: -0.5,
      value: 8,
      invertTrendColor: undefined,
    },
  },
];
