import { nMonthsBefore } from '~/lib/utils/datetime_utility';

const mockMetrics = ([
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

const THIS_MONTH = {
  key: 'thisMonth',
  label: 'Month to date',
  start: new Date('2020-07-01T00:00:00.000Z'),
  end: new Date('2020-07-06T00:00:00.000Z'),
};

const LAST_MONTH = {
  key: 'lastMonth',
  label: 'June',
  start: new Date('2020-06-01T00:00:00.000Z'),
  end: new Date('2020-06-30T23:59:59.000Z'),
};

const TWO_MONTHS_AGO = {
  key: 'twoMonthsAgo',
  label: 'May',
  start: new Date('2020-05-01T00:00:00.000Z'),
  end: new Date('2020-05-31T23:59:59.000Z'),
};

const THREE_MONTHS_AGO = {
  key: 'threeMonthsAgo',
  label: 'April',
  start: new Date('2020-04-01T00:00:00.000Z'),
  end: new Date('2020-04-30T23:59:59.000Z'),
};

export const MOCK_TABLE_TIME_PERIODS = [THIS_MONTH, LAST_MONTH, TWO_MONTHS_AGO, THREE_MONTHS_AGO];

// Generate the chart time periods, starting with the oldest first:
// 5 months ago -> 4 months ago -> etc.
export const MOCK_CHART_TIME_PERIODS = [5, 4, 3, 2, 1, 0].map((monthsAgo) => ({
  end: monthsAgo === 0 ? THIS_MONTH.end : nMonthsBefore(THIS_MONTH.end, monthsAgo),
  start: nMonthsBefore(THIS_MONTH.end, monthsAgo + 1),
}));

export const mockMonthToDate = mockMetrics([5.1, 4, 8, 0, 2, 4, 6, 8]);
export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockMetrics([3.6, 20, 4, 2, 4, '-', 12, 16]);
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockMetrics([9.2, 32, 8, 4, 2, '-', 6, 8]);
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockThreeMonthsAgo = mockMetrics([20.1, 32, 8, 2, 4, 8, 12, 16]);
export const mockThreeMonthsAgoTimePeriod = { ...THREE_MONTHS_AGO, ...mockThreeMonthsAgo };
export const mockThreeMonthsAgoApiResponse = Object.values(mockThreeMonthsAgo);

export const mockChartsTimePeriods = MOCK_CHART_TIME_PERIODS.map((timePeriod, i) => ({
  ...timePeriod,
  ...mockMetrics(['-', 0, 100 - i, i, i + 1, i * 2, 100 - i * 2, i * i]),
}));

export const mockComparativeTableData = [
  {
    metric: {
      value: 'Deployment Frequency',
      identifier: 'deployment_frequency',
    },
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
    metric: {
      value: 'Lead Time for Changes',
      identifier: 'lead_time_for_changes',
    },
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
    metric: {
      value: 'Time to Restore Service',
      identifier: 'time_to_restore_service',
    },
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
    metric: {
      value: 'Change Failure Rate',
      identifier: 'change_failure_rate',
    },
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
    metric: {
      value: 'Lead time',
      identifier: 'lead_time',
    },
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
    metric: {
      value: 'Cycle time',
      identifier: 'cycle_time',
    },
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
    metric: {
      value: 'New issues',
      identifier: 'issues',
    },
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
    metric: {
      value: 'Deploys',
      identifier: 'deploys',
    },
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

export const mockChartData = {
  lead_time_for_changes: {
    tooltipLabel: 'days',
    data: [
      [expect.anything(), '-'],
      [expect.anything(), '-'],
      [expect.anything(), '-'],
      [expect.anything(), '-'],
      [expect.anything(), '-'],
      [expect.anything(), '-'],
    ],
  },
  time_to_restore_service: {
    tooltipLabel: 'days',
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
  },
  change_failure_rate: {
    tooltipLabel: '%',
    data: [
      [expect.anything(), 100],
      [expect.anything(), 99],
      [expect.anything(), 98],
      [expect.anything(), 97],
      [expect.anything(), 96],
      [expect.anything(), 95],
    ],
  },
  deployment_frequency: {
    tooltipLabel: '/day',
    data: [
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 2],
      [expect.anything(), 3],
      [expect.anything(), 4],
      [expect.anything(), 5],
    ],
  },
  lead_time: {
    tooltipLabel: 'days',
    data: [
      [expect.anything(), 1],
      [expect.anything(), 2],
      [expect.anything(), 3],
      [expect.anything(), 4],
      [expect.anything(), 5],
      [expect.anything(), 6],
    ],
  },
  cycle_time: {
    tooltipLabel: 'days',
    data: [
      [expect.anything(), 0],
      [expect.anything(), 2],
      [expect.anything(), 4],
      [expect.anything(), 6],
      [expect.anything(), 8],
      [expect.anything(), 10],
    ],
  },
  issues: {
    tooltipLabel: undefined,
    data: [
      [expect.anything(), 100],
      [expect.anything(), 98],
      [expect.anything(), 96],
      [expect.anything(), 94],
      [expect.anything(), 92],
      [expect.anything(), 90],
    ],
  },
  deploys: {
    tooltipLabel: undefined,
    data: [
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 4],
      [expect.anything(), 9],
      [expect.anything(), 16],
      [expect.anything(), 25],
    ],
  },
};
