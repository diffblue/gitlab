export const ciMinutesUsageMockData = {
  data: {
    ciMinutesUsage: {
      nodes: [
        {
          month: 'June',
          monthIso8601: '2021-06-01',
          minutes: 5,
          sharedRunnersDuration: 60,
          projects: {
            nodes: [
              {
                name: 'devcafe-wp-theme',
                minutes: 5,
                sharedRunnersDuration: 60,
              },
            ],
          },
        },
        {
          month: 'July',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
          projects: {
            nodes: [],
          },
        },
        {
          month: 'August',
          monthIso8601: '2022-08-01',
          minutes: 0,
          sharedRunnersDuration: 0,
          projects: {
            nodes: [
              {
                name: 'devcafe-mx',
                minutes: 5,
                sharedRunnersDuration: 80,
              },
            ],
          },
        },
      ],
    },
  },
};
