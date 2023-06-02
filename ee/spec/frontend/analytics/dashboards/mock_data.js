import { nMonthsBefore } from '~/lib/utils/datetime_utility';
import { DORA_METRICS } from '~/analytics/shared/constants';

const mockMetrics = ([
  leadTimeForChanges,
  timeToRestoreService,
  changeFailureRate,
  deploymentFrequency,
  leadTime,
  cycleTime,
  issues,
  deploys,
  vulnerabilityCritical,
  vulnerabilityHigh,
  mergeRequestThroughput,
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
  vulnerability_critical: {
    value: vulnerabilityCritical,
    label: 'Critical Vulnerabilities over time',
    identifier: 'vulnerability_critical',
  },
  vulnerability_high: {
    value: vulnerabilityHigh,
    label: 'High Vulnerabilities  over time',
    identifier: 'vulnerability_high',
  },
  merge_request_throughput: {
    value: mergeRequestThroughput,
    label: 'Merge request throughput',
    identifier: 'merge_request_throughput',
  },
});

const THIS_MONTH = {
  key: 'thisMonth',
  label: 'Month to date',
  start: new Date('2020-07-01T00:00:00.000Z'),
  end: new Date('2020-07-06T00:00:00.000Z'),
  thClass: 'gl-w-20p',
};

const LAST_MONTH = {
  key: 'lastMonth',
  label: 'June',
  start: new Date('2020-06-01T00:00:00.000Z'),
  end: new Date('2020-06-30T23:59:59.000Z'),
  thClass: 'gl-w-20p',
};

const TWO_MONTHS_AGO = {
  key: 'twoMonthsAgo',
  label: 'May',
  start: new Date('2020-05-01T00:00:00.000Z'),
  end: new Date('2020-05-31T23:59:59.000Z'),
  thClass: 'gl-w-20p',
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
export const MOCK_CHART_TIME_PERIODS = [5, 4, 3, 2, 1, 0].map((monthsAgo, index) => ({
  end: monthsAgo === 0 ? THIS_MONTH.end : nMonthsBefore(THIS_MONTH.end, monthsAgo),
  start: nMonthsBefore(THIS_MONTH.end, monthsAgo + 1),
  key: `chart-period-${index}`,
}));

export const MOCK_DASHBOARD_TABLE_FIELDS = [
  {
    key: 'metric',
    label: 'Metric',
    thClass: 'gl-w-25p',
  },
  ...MOCK_TABLE_TIME_PERIODS.slice(0, -1),
  {
    key: 'chart',
    label: 'Past 6 Months',
    start: new Date('2020-01-06T00:00:00.000Z'),
    end: new Date('2020-07-06T00:00:00.000Z'),
    thClass: 'gl-w-15p',
    tdClass: 'gl-py-2!',
  },
];

export const mockMonthToDate = mockMetrics([0.5, 0.05, 0.005, 0, 2, 4, 6, 8, 3, 0, 5]);
export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockMetrics([3.6, 20, 4, 2, 4, '-', 12, 16, 0, 3, 2]);
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockMetrics([9.2, 32, 8, 4, 2, '-', 6, 8, 2, 0, 0]);
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockThreeMonthsAgo = mockMetrics([20.1, 32, 8, 2, 4, 8, 12, 16, 0, 0, 15]);
export const mockThreeMonthsAgoTimePeriod = { ...THREE_MONTHS_AGO, ...mockThreeMonthsAgo };
export const mockThreeMonthsAgoApiResponse = Object.values(mockThreeMonthsAgo);

export const mockChartsTimePeriods = MOCK_CHART_TIME_PERIODS.map((timePeriod, i) => ({
  ...timePeriod,
  ...mockMetrics(['-', undefined, 0, i, i + 1, i * 2, 100 - i * 2, i * i, i % 4, i % 2, i]),
}));

export const mockSubsetChartsTimePeriods = MOCK_CHART_TIME_PERIODS.slice(4).map(
  (timePeriod, i) => ({
    ...timePeriod,
    ...mockMetrics([i + 1, 100 - i]),
  }),
);

export const mockComparativeTableData = [
  {
    metric: {
      value: 'Deployment Frequency',
      identifier: 'deployment_frequency',
    },
    invertTrendColor: undefined,
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
    metric: {
      value: 'Lead Time for Changes',
      identifier: 'lead_time_for_changes',
    },
    invertTrendColor: true,
    thisMonth: {
      value: '0.5 d',
      change: -0.8611111111111112,
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
    metric: {
      value: 'Time to Restore Service',
      identifier: 'time_to_restore_service',
    },
    invertTrendColor: true,
    thisMonth: {
      value: '0.05 d',
      change: -0.9974999999999999,
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
    metric: {
      value: 'Change Failure Rate',
      identifier: 'change_failure_rate',
    },
    invertTrendColor: true,
    thisMonth: {
      value: '0.005%',
      change: -0.99875,
    },
    lastMonth: {
      value: '4.0%',
      change: -0.5,
    },
    twoMonthsAgo: {
      value: '8.0%',
      change: 0,
    },
  },
  {
    metric: {
      value: 'Lead time',
      identifier: 'lead_time',
    },
    invertTrendColor: true,
    lastMonth: {
      change: 1,
      value: '4.0 d',
    },
    thisMonth: {
      change: -0.5,
      value: '2.0 d',
    },
    twoMonthsAgo: {
      change: -0.5,
      value: '2.0 d',
    },
  },
  {
    metric: {
      value: 'Cycle time',
      identifier: 'cycle_time',
    },
    invertTrendColor: true,
    lastMonth: {
      change: 0,
      value: '-',
    },
    thisMonth: {
      change: 0,
      value: '4.0 d',
    },
    twoMonthsAgo: {
      change: 0,
      value: '-',
    },
  },
  {
    metric: {
      value: 'New issues',
      identifier: 'issues',
    },
    invertTrendColor: undefined,
    lastMonth: {
      change: 1,
      value: 12,
    },
    thisMonth: {
      change: -0.5,
      value: 6,
    },
    twoMonthsAgo: {
      change: -0.5,
      value: 6,
    },
  },
  {
    metric: {
      value: 'Deploys',
      identifier: 'deploys',
    },
    invertTrendColor: undefined,
    lastMonth: {
      change: 1,
      value: 16,
    },
    thisMonth: {
      change: -0.5,
      value: 8,
    },
    twoMonthsAgo: {
      change: -0.5,
      value: 8,
    },
  },
  {
    metric: {
      identifier: 'merge_request_throughput',
      value: 'Merge request throughput',
    },
    lastMonth: {
      change: 0,
      value: 2,
    },
    thisMonth: {
      change: 1.5,
      value: 5,
    },
    twoMonthsAgo: {
      change: 0,
      value: 0,
    },
  },
  {
    metric: {
      identifier: 'vulnerability_critical',
      value: 'Critical Vulnerabilities over time',
    },
    invertTrendColor: true,
    lastMonth: {
      change: null,
      value: 0,
    },
    thisMonth: {
      change: null,
      value: 3,
    },
    twoMonthsAgo: {
      change: null,
      value: 2,
    },
  },
  {
    metric: {
      identifier: 'vulnerability_high',
      value: 'High Vulnerabilities over time',
    },
    invertTrendColor: true,
    lastMonth: {
      change: null,
      value: 3,
    },
    thisMonth: {
      change: null,
      value: 0,
    },
    twoMonthsAgo: {
      change: null,
      value: 0,
    },
  },
];

export const mockSubsetChartData = {
  change_failure_rate: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: '%',
  },
  cycle_time: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: 'days',
  },
  deployment_frequency: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: '/day',
  },
  deploys: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: undefined,
  },
  issues: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: undefined,
  },
  lead_time: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: 'days',
  },
  lead_time_for_changes: {
    data: [
      [expect.anything(), 1],
      [expect.anything(), 2],
    ],
    tooltipLabel: 'days',
  },
  time_to_restore_service: {
    data: [
      [expect.anything(), 100],
      [expect.anything(), 99],
    ],
    tooltipLabel: 'days',
  },
  vulnerability_critical: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: undefined,
  },
  vulnerability_high: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: undefined,
  },
  merge_request_throughput: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 0],
    ],
    tooltipLabel: undefined,
  },
};

export const mockChartData = {
  lead_time_for_changes: {
    tooltipLabel: 'days',
    data: [
      [expect.anything(), null],
      [expect.anything(), null],
      [expect.anything(), null],
      [expect.anything(), null],
      [expect.anything(), null],
      [expect.anything(), null],
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
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
      [expect.anything(), 0],
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
  vulnerability_critical: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 2],
      [expect.anything(), 3],
      [expect.anything(), 0],
      [expect.anything(), 1],
    ],
    tooltipLabel: undefined,
  },
  vulnerability_high: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 0],
      [expect.anything(), 1],
    ],
    tooltipLabel: undefined,
  },
  merge_request_throughput: {
    data: [
      [expect.anything(), 0],
      [expect.anything(), 1],
      [expect.anything(), 2],
      [expect.anything(), 3],
      [expect.anything(), 4],
      [expect.anything(), 5],
    ],
    tooltipLabel: undefined,
  },
};

export const mockLastVulnerabilityCountData = {
  date: '2020-05-20',
  critical: 7,
  high: 6,
  medium: 5,
  low: 4,
};

export const mockDoraMetricsResponseData = {
  metrics: [
    {
      date: null,
      deployment_frequency: 23.75,
      change_failure_rate: 0.056578947368421055,
      lead_time_for_changes: 23508,
      time_to_restore_service: 72080,
      __typename: 'DoraMetric',
    },
  ],
  __typename: 'Dora',
};

export const mockFlowMetricsResponseData = {
  issues: {
    unit: null,
    value: 10,
    identifier: 'issues',
    links: [],
    title: 'New Issues',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  cycle_time: {
    unit: 'days',
    value: null,
    identifier: 'cycle_time',
    links: [],
    title: 'Cycle Time',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  lead_time: {
    unit: 'days',
    value: 10,
    identifier: 'lead_time',
    links: [
      {
        label: 'Dashboard',
        name: 'Lead Time',
        docsLink: null,
        url: '/groups/test-graphql-dora/-/issues_analytics',
        __typename: 'ValueStreamMetricLinkType',
      },
      {
        label: 'Go to docs',
        name: 'Lead Time',
        docsLink: true,
        url: '/help/user/analytics/index#definitions',
        __typename: 'ValueStreamMetricLinkType',
      },
    ],
    title: 'Lead Time',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  deploys: {
    unit: null,
    value: 751,
    identifier: 'deploys',
    links: [],
    title: 'Deploys',
    __typename: 'ValueStreamAnalyticsMetric',
  },
  __typename: 'GroupValueStreamAnalyticsFlowMetrics',
};

export const mockMergeRequestsResponseData = {
  merge_request_throughput: 10,
  __typename: 'MergeRequestConnection',
};

export const mockExcludeMetrics = [
  DORA_METRICS.DEPLOYMENT_FREQUENCY,
  DORA_METRICS.LEAD_TIME_FOR_CHANGES,
];

export const mockEmptyVulnerabilityResponse = [{ date: null, critical: null, high: null }];
export const mockEmptyDoraResponse = { metrics: [] };
export const mockEmptyMergeRequestsResponse = { mergeRequests: {} };
export const mockEmptyFlowMetricsResponse = {
  issues: null,
  deploys: null,
  cycle_time: null,
  lead_time: null,
};
