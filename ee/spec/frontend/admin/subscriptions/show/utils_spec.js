import {
  subscriptionTypes,
  offlineCloudLicenseText,
  onlineCloudLicenseText,
  licenseFileText,
} from 'ee/admin/subscriptions/show/constants';
import {
  getErrorsAsData,
  getLicenseFromData,
  getLicenseTypeLabel,
} from 'ee/admin/subscriptions/show/utils';

describe('utils', () => {
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

  describe('getLicenseTypeLabel', () => {
    const typeLabels = {
      OFFLINE_CLOUD: offlineCloudLicenseText,
      ONLINE_CLOUD: onlineCloudLicenseText,
      LEGACY_LICENSE: licenseFileText,
    };

    it.each(Object.keys(subscriptionTypes))('should return correct label for type', (key) => {
      expect(getLicenseTypeLabel(subscriptionTypes[key])).toBe(typeLabels[key]);
    });
  });
});
