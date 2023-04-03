import {
  getUsageDataByYear,
  getUsageDataByYearObject,
  formatYearMonthData,
  getSortedYears,
} from 'ee/usage_quotas/pipelines/utils';
import { mockGetCiMinutesUsageNamespace, pageInfo } from './mock_data';

const {
  data: {
    ciMinutesUsage: { nodes },
  },
} = mockGetCiMinutesUsageNamespace;

describe('CI Minutes Usage Utils', () => {
  it('getUsageDataByYear normalizes data by year', () => {
    const expectedDataByYear = {
      2021: [
        {
          day: '01',
          minutes: 5,
          month: 'June',
          monthIso8601: '2021-06-01',
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
          sharedRunnersDuration: 60,
          year: '2021',
        },
        {
          day: '01',
          minutes: 0,
          month: 'July',
          monthIso8601: '2021-07-01',
          projects: {
            nodes: [],
            pageInfo,
          },
          sharedRunnersDuration: 0,
          year: '2021',
        },
      ],
      2022: [
        {
          day: '01',
          minutes: 5,
          month: 'August',
          monthIso8601: '2022-08-01',
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
          sharedRunnersDuration: 80,
          year: '2022',
        },
      ],
    };

    expect(getUsageDataByYear(nodes)).toEqual(expectedDataByYear);
  });

  it('formatYearMonthData formats date', () => {
    const expectedFormat = [
      {
        day: '01',
        minutes: 5,
        month: 'June',
        monthIso8601: '2021-06-01',
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
        sharedRunnersDuration: 60,
        year: '2021',
      },
      {
        day: '01',
        minutes: 0,
        month: 'July',
        monthIso8601: '2021-07-01',
        projects: {
          nodes: [],
          pageInfo,
        },
        sharedRunnersDuration: 0,
        year: '2021',
      },
      {
        day: '01',
        minutes: 5,
        month: 'August',
        monthIso8601: '2022-08-01',
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
        sharedRunnersDuration: 80,
        year: '2022',
      },
    ];

    expect(formatYearMonthData(nodes)).toEqual(expectedFormat);
  });

  it('formatYearMonthData formats date and month if format param is passed', () => {
    const expectedFormat = [
      {
        day: '01',
        minutes: 5,
        month: 'June',
        monthIso8601: '2021-06-01',
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
        sharedRunnersDuration: 60,
        year: '2021',
      },
      {
        day: '01',
        minutes: 0,
        month: 'July',
        monthIso8601: '2021-07-01',
        projects: {
          nodes: [],
          pageInfo,
        },
        sharedRunnersDuration: 0,
        year: '2021',
      },
      {
        day: '01',
        minutes: 5,
        month: 'August',
        monthIso8601: '2022-08-01',
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
        sharedRunnersDuration: 80,
        year: '2022',
      },
    ];

    expect(formatYearMonthData(nodes, true)).toEqual(expectedFormat);
  });

  it('getSortedYears returns an array of years sorted in descending order', () => {
    const expectedYears = ['2022', '2021'];
    const usageDataByYear = getUsageDataByYear(nodes);

    expect(getSortedYears(usageDataByYear)).toEqual(expectedYears);
  });

  it('getUsageDataByYearObject normalizes data by year and by month', () => {
    const expectedDataByYearMonth = {
      2021: {
        June: {
          year: '2021',
          month: 'June',
          day: '01',
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
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 'eyJpZCI6IjYifQ',
              endCursor: 'eyJpZCI6IjYifQ',
            },
          },
        },
        July: {
          year: '2021',
          month: 'July',
          day: '01',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
          projects: {
            nodes: [],
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 'eyJpZCI6IjYifQ',
              endCursor: 'eyJpZCI6IjYifQ',
            },
          },
        },
      },
      2022: {
        August: {
          year: '2022',
          month: 'August',
          day: '01',
          monthIso8601: '2022-08-01',
          minutes: 5,
          sharedRunnersDuration: 80,
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
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 'eyJpZCI6IjYifQ',
              endCursor: 'eyJpZCI6IjYifQ',
            },
          },
        },
      },
    };

    expect(getUsageDataByYearObject(nodes)).toEqual(expectedDataByYearMonth);
  });
});
