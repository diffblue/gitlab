import { transformFilters } from 'ee/issues_analytics/utils';
import { mockOriginalFilters, mockFilters } from './mock_data';

describe('Issues Analytics utils', () => {
  describe('transformFilters', () => {
    it('transforms the object keys as expected', () => {
      const filters = transformFilters(mockOriginalFilters);

      expect(filters).toStrictEqual(mockFilters);
    });
  });
});
