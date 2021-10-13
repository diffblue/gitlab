import {
  getErrorsAsData,
  getLicenseFromData,
  updateSubscriptionAppCache,
} from 'ee/admin/subscriptions/show/graphql/utils';
import { activateLicenseMutationResponse } from '../mock_data';

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

  describe('updateSubscriptionAppCache', () => {
    const cache = {
      readQuery: jest.fn(() => ({ licenseHistoryEntries: { nodes: [] } })),
      writeQuery: jest.fn(),
    };

    it('calls writeQuery the correct number of times', () => {
      updateSubscriptionAppCache(cache, activateLicenseMutationResponse.SUCCESS);

      expect(cache.writeQuery).toHaveBeenCalledTimes(2);
    });

    it('calls writeQuery the first time to update the current subscription', () => {
      updateSubscriptionAppCache(cache, activateLicenseMutationResponse.SUCCESS);

      expect(cache.writeQuery.mock.calls[0][0]).toEqual(
        expect.objectContaining({
          data: {
            currentLicense:
              activateLicenseMutationResponse.SUCCESS.data.gitlabSubscriptionActivate.license,
          },
        }),
      );
    });

    it('calls writeQuery the second time to update the subscription history', () => {
      updateSubscriptionAppCache(cache, activateLicenseMutationResponse.SUCCESS);

      expect(cache.writeQuery.mock.calls[1][0]).toEqual(
        expect.objectContaining({
          data: {
            licenseHistoryEntries: {
              nodes: [
                activateLicenseMutationResponse.SUCCESS.data.gitlabSubscriptionActivate.license,
              ],
            },
          },
        }),
      );
    });
  });
});
