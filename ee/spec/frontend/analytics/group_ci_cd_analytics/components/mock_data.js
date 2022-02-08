export const groupReleaseStatsQueryResponse = {
  data: {
    group: {
      id: '1',
      stats: {
        releaseStats: {
          releasesCount: 2811,
          releasesPercentage: 9,
        },
      },
    },
  },
};

export const ciMinutesUsageNamespace = {
  data: {
    ciMinutesUsage: {
      nodes: [
        {
          month: 'December',
          monthIso8601: '2021-12-01',
          sharedRunnersDuration: 110,
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'November',
          monthIso8601: '2021-11-01',
          sharedRunnersDuration: 95,
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'October',
          monthIso8601: '2021-10-01',
          sharedRunnersDuration: 85,
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'September',
          monthIso8601: '2021-09-01',
          sharedRunnersDuration: 85,
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
      ],
    },
  },
};
