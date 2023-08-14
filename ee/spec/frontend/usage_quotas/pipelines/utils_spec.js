import {
  getUsageDataByYearAsArray,
  getUsageDataByYearByMonthAsObject,
  formatIso8601Date,
} from 'ee/usage_quotas/pipelines/utils';
import { mockGetCiMinutesUsageNamespace } from './mock_data';

const {
  data: {
    ciMinutesUsage: { nodes },
  },
} = mockGetCiMinutesUsageNamespace;

describe('CI Minutes Usage Utils', () => {
  it('getUsageDataByYearAsArray normalizes data by year', () => {
    const expectedDataByYear = {
      2021: [
        {
          date: new Date('2021-06-01'),
          day: '01',
          month: 'June',
          year: '2021',
          monthIso8601: '2021-06-01',
          minutes: 5,
          sharedRunnersDuration: 60,
        },
        {
          date: new Date('2021-07-01'),
          day: '01',
          month: 'July',
          year: '2021',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
        },
      ],
      2022: [
        {
          date: new Date('2022-08-01'),
          day: '01',
          month: 'August',
          year: '2022',
          monthIso8601: '2022-08-01',
          minutes: 5,
          sharedRunnersDuration: 80,
        },
      ],
    };

    expect(getUsageDataByYearAsArray(nodes)).toEqual(expectedDataByYear);
  });

  it('getUsageDataByYearByMonthAsObject normalizes data by year and by month', () => {
    const expectedDataByYearMonth = {
      2021: {
        6: {
          date: new Date('2021-06-01'),
          day: '01',
          month: 'June',
          year: '2021',
          monthIso8601: '2021-06-01',
          minutes: 5,
          sharedRunnersDuration: 60,
        },
        7: {
          date: new Date('2021-07-01'),
          day: '01',
          month: 'July',
          year: '2021',
          monthIso8601: '2021-07-01',
          minutes: 0,
          sharedRunnersDuration: 0,
        },
      },
      2022: {
        8: {
          date: new Date('2022-08-01'),
          day: '01',
          month: 'August',
          year: '2022',
          monthIso8601: '2022-08-01',
          minutes: 5,
          sharedRunnersDuration: 80,
        },
      },
    };

    expect(getUsageDataByYearByMonthAsObject(nodes)).toEqual(expectedDataByYearMonth);
  });

  describe('formatIso8601Date', () => {
    it('creates a ISO-8601 formated date', () => {
      expect(formatIso8601Date(2021, 6, 1)).toBe('2021-06-01');
    });
  });
});
