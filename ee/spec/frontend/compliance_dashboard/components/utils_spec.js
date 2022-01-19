import * as utils from 'ee/compliance_dashboard/utils';

describe('compliance report utils', () => {
  describe('convertProjectIdsToGraphQl', () => {
    it('returns the expected result', () => {
      expect(utils.convertProjectIdsToGraphQl(['1', '2'])).toStrictEqual([
        'gid://gitlab/Project/1',
        'gid://gitlab/Project/2',
      ]);
    });
  });
});
