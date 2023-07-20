import { isUndefined } from 'lodash';
import { nMonthsBefore } from '~/lib/utils/datetime_utility';
import { DORA_METRICS } from '~/analytics/shared/constants';

const METRIC_IDENTIFIERS = [
  'lead_time_for_changes',
  'time_to_restore_service',
  'change_failure_rate',
  'deployment_frequency',
  'lead_time',
  'cycle_time',
  'issues',
  'issues_completed',
  'deploys',
  'vulnerability_critical',
  'vulnerability_high',
  'merge_request_throughput',
];

const hasValue = (obj, key) => !isUndefined(obj[key]) && obj[key] !== null;

const mockMetrics = (mockValues = {}) =>
  METRIC_IDENTIFIERS.filter((identifier) => hasValue(mockValues, identifier)).reduce(
    (data, identifier) => ({
      ...data,
      [identifier]: {
        identifier,
        value: mockValues[identifier],
      },
    }),
    {},
  );

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

export const mockMonthToDate = mockMetrics({
  lead_time_for_changes: 0.5,
  time_to_restore_service: 0.05,
  change_failure_rate: 0.005,
  deployment_frequency: 0,
  lead_time: 2,
  cycle_time: 4,
  issues: 6,
  issues_completed: 10080,
  deploys: 8,
  vulnerability_critical: 3,
  vulnerability_high: 0,
  merge_request_throughput: 5,
});

export const mockMonthToDateTimePeriod = { ...THIS_MONTH, ...mockMonthToDate };
export const mockMonthToDateApiResponse = Object.values(mockMonthToDate);

export const mockPreviousMonth = mockMetrics({
  lead_time_for_changes: 3.6,
  time_to_restore_service: 20,
  change_failure_rate: 4,
  deployment_frequency: 2,
  lead_time: 4,
  cycle_time: '-',
  issues: 12,
  issues_completed: 9000,
  deploys: 16,
  vulnerability_critical: 0,
  vulnerability_high: 3,
  merge_request_throughput: 2,
});
export const mockPreviousMonthTimePeriod = { ...LAST_MONTH, ...mockPreviousMonth };
export const mockPreviousMonthApiResponse = Object.values(mockPreviousMonth);

export const mockTwoMonthsAgo = mockMetrics({
  lead_time_for_changes: 9.2,
  time_to_restore_service: 32,
  change_failure_rate: 8,
  deployment_frequency: 4,
  lead_time: 2,
  cycle_time: '-',
  issues: 6,
  issues_completed: 6000,
  deploys: 8,
  vulnerability_critical: 2,
  vulnerability_high: 0,
  merge_request_throughput: 0,
});
export const mockTwoMonthsAgoTimePeriod = { ...TWO_MONTHS_AGO, ...mockTwoMonthsAgo };
export const mockTwoMonthsAgoApiResponse = Object.values(mockTwoMonthsAgo);

export const mockThreeMonthsAgo = mockMetrics({
  lead_time_for_changes: 20.1,
  time_to_restore_service: 32,
  change_failure_rate: 8,
  deployment_frequency: 2,
  lead_time: 4,
  cycle_time: 8,
  issues: 12,
  issues_completed: 8000,
  deploys: 16,
  vulnerability_critical: 0,
  vulnerability_high: 0,
  merge_request_throughput: 15,
});
export const mockThreeMonthsAgoTimePeriod = { ...THREE_MONTHS_AGO, ...mockThreeMonthsAgo };
export const mockThreeMonthsAgoApiResponse = Object.values(mockThreeMonthsAgo);

export const mockChartsTimePeriods = MOCK_CHART_TIME_PERIODS.map((timePeriod, i) => ({
  ...timePeriod,
  ...mockMetrics({
    lead_time_for_changes: '-',
    time_to_restore_service: undefined,
    change_failure_rate: 0,
    deployment_frequency: i,
    lead_time: i + 1,
    cycle_time: i * 2,
    issues: 100 - i * 2,
    issues_completed: 200 - i * 2,
    deploys: i * i,
    vulnerability_critical: i % 4,
    vulnerability_high: i % 2,
    merge_request_throughput: i,
  }),
}));

export const mockSubsetChartsTimePeriods = MOCK_CHART_TIME_PERIODS.slice(4).map(
  (timePeriod, i) => ({
    ...timePeriod,
    ...mockMetrics({ lead_time_for_changes: i + 1, time_to_restore_service: 100 - i }),
  }),
);

export const mockComparativeTableData = [
  {
    metric: {
      value: 'Deployment Frequency',
      identifier: 'deployment_frequency',
    },
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
      value: 'Closed issues',
      identifier: 'issues_completed',
    },
    valueLimit: {
      max: 10001,
      mask: '10000+',
      description:
        'This is a lower-bound approximation. Your group has too many issues and MRs to calculate in real time.',
    },
    lastMonth: {
      change: 0.5,
      value: 9000,
    },
    thisMonth: {
      change: 0.12,
      value: '10000+',
      valueLimitMessage:
        'This is a lower-bound approximation. Your group has too many issues and MRs to calculate in real time.',
    },
    twoMonthsAgo: {
      change: -0.25,
      value: 6000,
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

const mockChartDataValues = (values) => values.map((v) => [expect.anything(), v]);

const mockChartDataWithSameValue = (count, value) =>
  mockChartDataValues([...Array(count).keys()].map(() => value));

export const mockSubsetChartData = {
  change_failure_rate: {
    data: mockChartDataWithSameValue(2, 0),
    tooltipLabel: '%',
  },
  cycle_time: {
    data: mockChartDataWithSameValue(2, 0),
    tooltipLabel: 'days',
  },
  deployment_frequency: {
    data: mockChartDataWithSameValue(2, 0),
    tooltipLabel: '/day',
  },
  deploys: {
    data: mockChartDataWithSameValue(2, 0),
  },
  issues: {
    data: mockChartDataWithSameValue(2, 0),
  },
  issues_completed: {
    data: mockChartDataWithSameValue(2, 0),
  },
  lead_time: {
    data: mockChartDataWithSameValue(2, 0),
    tooltipLabel: 'days',
  },
  lead_time_for_changes: {
    data: mockChartDataValues([1, 2]),
    tooltipLabel: 'days',
  },
  time_to_restore_service: {
    data: mockChartDataValues([100, 99]),
    tooltipLabel: 'days',
  },
  vulnerability_critical: {
    data: mockChartDataWithSameValue(2, 0),
  },
  vulnerability_high: {
    data: mockChartDataWithSameValue(2, 0),
  },
  merge_request_throughput: {
    data: mockChartDataWithSameValue(2, 0),
  },
};

export const mockChartData = {
  lead_time_for_changes: {
    tooltipLabel: 'days',
    data: mockChartDataWithSameValue(6, null),
  },
  time_to_restore_service: {
    tooltipLabel: 'days',
    data: mockChartDataWithSameValue(6, 0),
  },
  change_failure_rate: {
    tooltipLabel: '%',
    data: mockChartDataWithSameValue(6, 0),
  },
  deployment_frequency: {
    tooltipLabel: '/day',
    data: mockChartDataValues([0, 1, 2, 3, 4, 5]),
  },
  lead_time: {
    tooltipLabel: 'days',
    data: mockChartDataValues([1, 2, 3, 4, 5, 6]),
  },
  cycle_time: {
    tooltipLabel: 'days',
    data: mockChartDataValues([0, 2, 4, 6, 8, 10]),
  },
  issues: {
    data: mockChartDataValues([100, 98, 96, 94, 92, 90]),
  },
  issues_completed: {
    data: mockChartDataValues([200, 198, 196, 194, 192, 190]),
  },
  deploys: {
    data: mockChartDataValues([0, 1, 4, 9, 16, 25]),
  },
  vulnerability_critical: {
    data: mockChartDataValues([0, 1, 2, 3, 0, 1]),
  },
  vulnerability_high: {
    data: mockChartDataValues([0, 1, 0, 1, 0, 1]),
  },
  merge_request_throughput: {
    data: mockChartDataValues([0, 1, 2, 3, 4, 5]),
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
  issues_completed: {
    unit: 'issues',
    value: 109,
    identifier: 'issues_completed',
    links: [
      {
        label: 'Dashboard',
        name: 'Issues Completed',
        docsLink: null,
        url: '/groups/toolbox/-/issues_analytics',
        __typename: 'ValueStreamMetricLinkType',
      },
      {
        label: 'Go to docs',
        name: 'Issues Completed',
        docsLink: true,
        url: '/help/user/analytics/index#definitions',
        __typename: 'ValueStreamMetricLinkType',
      },
    ],
    title: 'Issues Completed',
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
  issues_completed: null,
  deploys: null,
  cycle_time: null,
  lead_time: null,
};

export const MOCK_LABELS = [
  { id: 1, title: 'one', color: '#FFFFFF' },
  { id: 2, title: 'two', color: '#000000' },
  { id: 3, title: 'three', color: '#0F0F0F' },
];

export const filterLabelsGroupQuery = `query ($fullPath: ID!) {
  namespace: group(fullPath: $fullPath) {
    id
    label_0: labels(
      searchTerm: "zero"
      includeAncestorGroups: true
      includeDescendantGroups: true
    ) {
      nodes {
        id
        title
        color
      }
    }
    label_1: labels(
      searchTerm: "one"
      includeAncestorGroups: true
      includeDescendantGroups: true
    ) {
      nodes {
        id
        title
        color
      }
    }
  }
}
`;

export const filterLabelsProjectQuery = `query ($fullPath: ID!) {
  namespace: project(fullPath: $fullPath) {
    id
    label_0: labels(searchTerm: "zero", includeAncestorGroups: true) {
      nodes {
        id
        title
        color
      }
    }
    label_1: labels(searchTerm: "one", includeAncestorGroups: true) {
      nodes {
        id
        title
        color
      }
    }
  }
}
`;

export const mockDoraPerformersScoreResponseData = [
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'deployment_frequency',
    lowProjectsCount: 27,
    mediumProjectsCount: 24,
    highProjectsCount: 86,
    noDataProjectsCount: 1,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'lead_time_for_changes',
    lowProjectsCount: 25,
    mediumProjectsCount: 30,
    highProjectsCount: 75,
    noDataProjectsCount: 1,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'time_to_restore_service',
    lowProjectsCount: 80,
    mediumProjectsCount: 55,
    highProjectsCount: 15,
    noDataProjectsCount: 1,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'change_failure_rate',
    lowProjectsCount: 81,
    mediumProjectsCount: 70,
    highProjectsCount: 5,
    noDataProjectsCount: 1,
  },
];

export const mockEmptyDoraPerformersScoreResponseData = [
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'deployment_frequency',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: 0,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'lead_time_for_changes',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: 0,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'time_to_restore_service',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: 0,
  },
  {
    __typename: 'DoraPerformanceScoreCount',
    metricName: 'change_failure_rate',
    lowProjectsCount: null,
    mediumProjectsCount: null,
    highProjectsCount: null,
    noDataProjectsCount: 0,
  },
];

export const mockDoraPerformersScoreChartData = [
  {
    name: 'High',
    data: [86, 75, 15, 5],
  },
  {
    name: 'Medium',
    data: [24, 30, 55, 70],
  },
  {
    name: 'Low',
    data: [27, 25, 80, 81],
  },
  {
    name: 'Not included',
    data: [1, 1, 1, 1],
  },
];
