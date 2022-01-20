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
          minutes: 110,
          projects: { nodes: [], __typename: 'CiMinutesProjectMonthlyUsageConnection' },
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'November',
          monthIso8601: '2021-11-01',
          minutes: 95,
          projects: {
            nodes: [
              { name: 'Html5 Boilerplate', minutes: 0, __typename: 'CiMinutesProjectMonthlyUsage' },
            ],
            __typename: 'CiMinutesProjectMonthlyUsageConnection',
          },
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'October',
          monthIso8601: '2021-10-01',
          minutes: 85,
          projects: { nodes: [], __typename: 'CiMinutesProjectMonthlyUsageConnection' },
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
        {
          month: 'September',
          monthIso8601: '2021-09-01',
          minutes: 85,
          projects: { nodes: [], __typename: 'CiMinutesProjectMonthlyUsageConnection' },
          __typename: 'CiMinutesNamespaceMonthlyUsage',
        },
      ],
    },
  },
};
