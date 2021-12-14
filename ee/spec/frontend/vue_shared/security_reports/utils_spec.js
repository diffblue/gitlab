import * as utils from 'ee/vue_shared/security_reports/utils';

describe('utils', () => {
  describe('getSecurityTabPath', () => {
    it.each([
      [undefined, '/security'],
      ['', '/security'],
      ['/foo/bar', '/foo/bar/security'],
    ])("when input is %p, returns '%s'", (input, expected) => {
      expect(utils.getSecurityTabPath(input)).toBe(expected);
    });
  });
});
