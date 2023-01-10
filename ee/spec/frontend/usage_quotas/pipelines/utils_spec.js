import {
  getUsageDataByYear,
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
          month: '06',
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
          month: '07',
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
          month: '08',
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
        month: '06',
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
        month: '07',
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
        month: '08',
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
        month: '06',
        monthIso8601: '2021-06-01',
        monthName: 'June',
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
        month: '07',
        monthIso8601: '2021-07-01',
        monthName: 'July',
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
        month: '08',
        monthIso8601: '2022-08-01',
        monthName: 'August',
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
});
