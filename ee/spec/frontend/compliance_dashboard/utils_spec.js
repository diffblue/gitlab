import timezoneMock from 'timezone-mock';
import * as utils from 'ee/compliance_dashboard/utils';
import { queryToObject } from '~/lib/utils/url_utility';

jest.mock('ee/audit_events/constants', () => ({
  CURRENT_DATE: new Date('2022 2 28'),
}));

describe('compliance report utils', () => {
  const projectIds = ['1', '2'];
  const projectGraphQlIds = ['gid://gitlab/Project/1', 'gid://gitlab/Project/2'];

  describe('parseViolationsQueryFilter', () => {
    it('returns the expected result', () => {
      const query = {
        projectIds,
        mergedAfter: '2021-12-06',
        mergedBefore: '2022-01-06',
      };

      expect(utils.parseViolationsQueryFilter(query)).toStrictEqual({
        projectIds: projectGraphQlIds,
        mergedAfter: query.mergedAfter,
        mergedBefore: query.mergedBefore,
      });
    });

    describe('given a negative UTC timezone', () => {
      beforeAll(() => {
        timezoneMock.register('US/Pacific');
      });

      afterAll(() => {
        timezoneMock.unregister();
      });

      // See https://gitlab.com/gitlab-org/gitlab/-/issues/367675#note_1025545194
      it('ignores the users timezone and uses base UTC for the date', () => {
        const query = {
          projectIds,
          mergedAfter: '2021-12-06',
          mergedBefore: '2022-01-06',
        };

        expect(utils.parseViolationsQueryFilter(query)).toStrictEqual({
          projectIds: projectGraphQlIds,
          mergedAfter: query.mergedAfter,
          mergedBefore: query.mergedBefore,
        });
      });
    });
  });

  describe('convertProjectIdsToGraphQl', () => {
    it('returns the expected result', () => {
      expect(utils.convertProjectIdsToGraphQl(projectIds)).toStrictEqual(projectGraphQlIds);
    });
  });

  describe('buildDefaultFilterParams', () => {
    it('returns the expected result with the default date range of 30 days', () => {
      const queryString = 'projectIds[]=20';

      expect(utils.buildDefaultFilterParams(queryString)).toStrictEqual({
        mergedAfter: '2022-01-29',
        mergedBefore: '2022-02-28',
        projectIds: ['20'],
      });
    });

    it('return the expected result when the query contains dates', () => {
      const queryString = 'mergedAfter=2022-02-09&mergedBefore=2022-03-11&projectIds[]=20';

      expect(utils.buildDefaultFilterParams(queryString)).toStrictEqual(
        queryToObject(queryString, { gatherArrays: true }),
      );
    });
  });
});
