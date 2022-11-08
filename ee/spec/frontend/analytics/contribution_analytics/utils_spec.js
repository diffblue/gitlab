import { formatChartData } from 'ee/analytics/contribution_analytics/utils';

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
});
