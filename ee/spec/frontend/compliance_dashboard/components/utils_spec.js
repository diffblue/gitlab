import * as utils from 'ee/compliance_dashboard/utils';

describe('compliance report utils', () => {
  describe('parseViolationsQuery', () => {
    it('returns the expected result', () => {
      const query = {
        projectIds: ['1', '2'],
        createdAfter: '2021-12-06',
        createdBefore: '2022-01-06',
      };

      expect(utils.parseViolationsQuery(query)).toStrictEqual({
        projectIds: ['gid://gitlab/Project/1', 'gid://gitlab/Project/2'],
        createdAfter: query.createdAfter,
        createdBefore: query.createdBefore,
      });
    });
  });
});
