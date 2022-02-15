import { getErrorsAsData, getLicenseFromData } from 'ee/admin/subscriptions/show/graphql/utils';

describe('graphQl utils', () => {
  describe('getLicenseFromData', () => {
    const license = { id: 'license-id' };
    const gitlabSubscriptionActivate = { license };

    it('returns the license data', () => {
      const result = getLicenseFromData({ data: { gitlabSubscriptionActivate } });

      expect(result).toMatchObject(license);
    });

    it('returns undefined with no subscription', () => {
      const result = getLicenseFromData({ data: { gitlabSubscriptionActivate: null } });

      expect(result).toBeUndefined();
    });

    it('returns undefined with no data', () => {
      const result = getLicenseFromData({ data: null });

      expect(result).toBeUndefined();
    });

    it('returns undefined with no params passed', () => {
      const result = getLicenseFromData();

      expect(result).toBeUndefined();
    });
  });

  describe('getErrorsAsData', () => {
    const errors = ['an error'];
    const gitlabSubscriptionActivate = { errors };

    it('returns the errors data', () => {
      const result = getErrorsAsData({ data: { gitlabSubscriptionActivate } });

      expect(result).toEqual(errors);
    });

    it('returns an empty array with no errors', () => {
      const result = getErrorsAsData({ data: { gitlabSubscriptionActivate: null } });

      expect(result).toEqual([]);
    });

    it('returns an empty array with no data', () => {
      const result = getErrorsAsData({ data: null });

      expect(result).toEqual([]);
    });

    it('returns an empty array with no params passed', () => {
      const result = getErrorsAsData();

      expect(result).toEqual([]);
    });
  });
});
