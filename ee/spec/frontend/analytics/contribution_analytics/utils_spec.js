import {
  formatChartData,
  filterPushes,
  filterMergeRequests,
  filterIssues,
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
          count: 47,
          user: 'Mr Krabs',
        },
        {
          count: 12,
          user: 'Patrick',
        },
      ]);
    });
  });

  describe('filterMergeRequests', () => {
    it('returns the filtered merge request data in the correct format', () => {
      const result = filterMergeRequests(MOCK_CONTRIBUTIONS);

      expect(result).toEqual([
        {
          closed: 99,
          created: 0,
          merged: 15,
          user: 'Mr Krabs',
        },
        {
          closed: 75,
          created: 234,
          merged: 35,
          user: 'Spongebob',
        },
      ]);
    });
  });

  describe('filterIssues', () => {
    it('returns the filtered issue data in the correct format', () => {
      const result = filterIssues(MOCK_CONTRIBUTIONS);

      expect(result).toEqual([
        {
          closed: 57,
          created: 55,
          user: 'Patrick',
        },
        {
          closed: 34,
          created: 75,
          user: 'Spongebob',
        },
      ]);
    });
  });
});
