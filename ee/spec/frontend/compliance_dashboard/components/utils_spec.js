import * as utils from 'ee/compliance_dashboard/utils';

describe('compliance report utils', () => {
  const projectIds = ['1', '2'];
  const projectGraphQlIds = ['gid://gitlab/Project/1', 'gid://gitlab/Project/2'];

  describe('parseViolationsQueryFilter', () => {
    it('returns the expected result', () => {
      const query = {
        projectIds,
        createdAfter: '2021-12-06',
        createdBefore: '2022-01-06',
      };

      expect(utils.parseViolationsQueryFilter(query)).toStrictEqual({
        projectIds: projectGraphQlIds,
        createdAfter: query.createdAfter,
        createdBefore: query.createdBefore,
      });
    });
  });

  describe('convertProjectIdsToGraphQl', () => {
    it('returns the expected result', () => {
      expect(utils.convertProjectIdsToGraphQl(projectIds)).toStrictEqual(projectGraphQlIds);
    });
  });
});
