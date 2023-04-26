import {
  formatChartData,
  filterPushes,
  filterMergeRequests,
  filterIssues,
  restrictRequestEndDate,
  mergeContributions,
} from 'ee/analytics/contribution_analytics/utils';
import { MOCK_CONTRIBUTIONS } from './mock_data';

describe('utils', () => {
  describe('formatChartData', () => {
    it('matches the corresponding label and sorts by value', () => {
      const result = formatChartData([10, 20, 30], ['Bart', 'Lisa', 'Maggie']);

      expect(result).toEqual([
        ['Maggie', 30],
        ['Lisa', 20],
        ['Bart', 10],
      ]);
    });
  });

  describe('filterPushes', () => {
    it('returns the filtered push data in the correct format', () => {
      const result = filterPushes(MOCK_CONTRIBUTIONS);

      expect(result).toEqual([
        {
          count: 1,
          user: 'Aaron',
        },
        {
          count: 2,
          user: 'Bob',
        },
        {
          count: 3,
          user: 'Carl',
        },
      ]);
    });
  });

  describe('filterMergeRequests', () => {
    it('returns the filtered merge request data in the correct format', () => {
      const result = filterMergeRequests(MOCK_CONTRIBUTIONS);

      expect(result).toEqual([
        {
          closed: 1,
          created: 1,
          merged: 1,
          user: 'Aaron',
        },
        {
          closed: 2,
          created: 2,
          merged: 2,
          user: 'Bob',
        },
        {
          closed: 3,
          created: 3,
          merged: 3,
          user: 'Carl',
        },
      ]);
    });
  });

  describe('filterIssues', () => {
    it('returns the filtered issue data in the correct format', () => {
      const result = filterIssues(MOCK_CONTRIBUTIONS);

      expect(result).toEqual([
        {
          closed: 1,
          created: 1,
          user: 'Aaron',
        },
        {
          closed: 2,
          created: 2,
          user: 'Bob',
        },
        {
          closed: 3,
          created: 3,
          user: 'Carl',
        },
      ]);
    });
  });

  describe('restrictRequestEndDate', () => {
    const endDate = '2000-12-31';
    it.each`
      startDate       | result
      ${'2000-12-31'} | ${{ endDate, nextStartDate: null }}
      ${'2000-12-30'} | ${{ endDate, nextStartDate: null }}
      ${'2000-12-24'} | ${{ endDate, nextStartDate: null }}
      ${'2000-12-23'} | ${{ endDate: '2000-12-30', nextStartDate: '2000-12-31' }}
      ${'2000-11-25'} | ${{ endDate: '2000-12-02', nextStartDate: '2000-12-03' }}
    `('restricted date range: $startDate ... $result.endDate', ({ startDate, result }) => {
      expect(restrictRequestEndDate(startDate, endDate)).toEqual(result);
    });
  });

  describe('mergeContributions', () => {
    it('takes the value from the second array when there is no user match', () => {
      expect(mergeContributions([], MOCK_CONTRIBUTIONS)).toEqual(MOCK_CONTRIBUTIONS);
    });

    it('takes the value from the first array when there is no user match', () => {
      expect(mergeContributions(MOCK_CONTRIBUTIONS, [])).toEqual(MOCK_CONTRIBUTIONS);
    });

    it('combines the metric values when there is a user match', () => {
      const match = {
        repoPushed: 100,
        mergeRequestsCreated: 100,
        mergeRequestsMerged: 100,
        mergeRequestsClosed: 100,
        mergeRequestsApproved: 100,
        issuesCreated: 100,
        issuesClosed: 100,
        totalEvents: 100,
        user: MOCK_CONTRIBUTIONS[0].user,
      };

      expect(mergeContributions(MOCK_CONTRIBUTIONS, [match])).toEqual([
        {
          repoPushed: 101,
          mergeRequestsCreated: 101,
          mergeRequestsMerged: 101,
          mergeRequestsClosed: 101,
          mergeRequestsApproved: 101,
          issuesCreated: 101,
          issuesClosed: 101,
          totalEvents: 107,
          user: match.user,
        },
        ...MOCK_CONTRIBUTIONS.slice(1),
      ]);
    });
  });
});
