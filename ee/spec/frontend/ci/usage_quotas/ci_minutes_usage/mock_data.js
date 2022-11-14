export const pageInfo = {
  __typename: 'PageInfo',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjYifQ',
  endCursor: 'eyJpZCI6IjYifQ',
};

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
                minutes: 5,
                sharedRunnersDuration: 60,
                project: {
                  id: 'gid://gitlab/Project/6',
                  name: 'devcafe-wp-theme',
                  nameWithNamespace: 'Group / devcafe-wp-theme',
                  avatarUrl: null,
                  webUrl: 'http://gdk.test:3000/group/devcafe-wp-theme',
                },
              },
            ],
            pageInfo,
          },
        },
        {
          month: 'July',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
          projects: {
            nodes: [],
            pageInfo,
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
                minutes: 5,
                sharedRunnersDuration: 80,
                project: {
                  id: 'gid://gitlab/Project/7',
                  name: 'devcafe-mx',
                  nameWithNamespace: 'Group / devcafe-mx',
                  avatarUrl: null,
                  webUrl: 'http://gdk.test:3000/group/devcafe-mx',
                },
              },
            ],
            pageInfo,
          },
        },
      ],
    },
  },
};
