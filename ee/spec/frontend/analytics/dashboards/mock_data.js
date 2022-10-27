const mockLeadTimeForChanges = {
  value: '0.2',
  unit: 'days',
  label: 'Lead Time for Changes',
  identifier: 'lead_time_for_changes',
};

const mockTimeToRestore = {
  value: '0.4',
  unit: 'days',
  label: 'Time to Restore Service',
  identifier: 'time_to_restore_service',
};

const mockChangeFailureRate = {
  value: '8.54',
  unit: '%',
  label: 'Change Failure Rate',
  identifier: 'change_failure_rate',
};

const mockDeploymentFrequency = {
  value: '19.9',
  unit: '/day',
  label: 'Deployment Frequency',
  identifier: 'deployment_frequency',
};

export const mockCurrentTimePeriod = {
  lead_time_for_changes: mockLeadTimeForChanges,
  time_to_restore_service: mockTimeToRestore,
  change_failure_rate: mockChangeFailureRate,
  deployment_frequency: mockDeploymentFrequency,
};

const mockPreviousValues = [2.5, 22.32, 5.2, 1.7];
export const mockPreviousTimePeriod = Object.entries(mockCurrentTimePeriod).reduce(
  (acc, [key, data], index) => ({
    ...acc,
    [key]: {
      ...data,
      value: mockPreviousValues[index],
    },
  }),
  {},
);

export const mockCurrentApiResponse = Object.values(mockCurrentTimePeriod);
export const mockPreviousApiResponse = Object.values(mockPreviousTimePeriod);

export const mockComparativeTableData = [
  {
    change: '1070.59%',
    current: '19.9/d',
    metric: 'Deployment Frequency',
    previous: '1.7/d',
  },
  {
    change: '-92%',
    current: '0.2 d',
    metric: 'Lead Time for Changes',
    previous: '2.5 d',
  },
  {
    change: '-98.21%',
    current: '0.4 d',
    metric: 'Time to Restore Service',
    previous: '22.32 d',
  },
  {
    change: '64.23%',
    current: '8.54%',
    metric: 'Change Failure Rate',
    previous: '5.2%',
  },
];

export const mockMetricsResponse = [
  mockLeadTimeForChanges,
  mockChangeFailureRate,
  mockTimeToRestore,
  mockDeploymentFrequency,
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
