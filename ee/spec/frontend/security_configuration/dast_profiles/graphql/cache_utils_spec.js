import { gql } from '@apollo/client/core';
import {
  removeProfile,
  dastProfilesDeleteResponse,
  updateSiteProfilesStatuses,
} from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import { siteProfiles } from '../mocks/mock_data';

describe('EE - DastProfiles GraphQL CacheUtils', () => {
  describe('removeProfile', () => {
    it('removes the profile from the cache', () => {
      const [profileToBeRemoved] = siteProfiles;
      const mockStore = {
        identify: jest.fn().mockReturnValue(profileToBeRemoved.id),
        evict: jest.fn(),
      };

      removeProfile({
        profile: profileToBeRemoved,
        store: mockStore,
      });

      expect(mockStore.identify).toHaveBeenCalledWith(profileToBeRemoved);
      expect(mockStore.evict).toHaveBeenCalledWith({ id: profileToBeRemoved.id });
    });
  });

  describe('dastProfilesDeleteResponse', () => {
    it('returns a mutation response with the correct shape', () => {
      const mockMutationName = 'mutationName';
      const mockPayloadTypeName = 'payloadTypeName';

      expect(
        dastProfilesDeleteResponse({
          mutationName: mockMutationName,
          payloadTypeName: mockPayloadTypeName,
        }),
      ).toEqual({
        __typename: 'Mutation',
        [mockMutationName]: {
          __typename: mockPayloadTypeName,
          errors: [],
        },
      });
    });
  });

  describe('updateSiteProfilesStatuses', () => {
    it.each`
      siteProfile        | status
      ${siteProfiles[0]} | ${'PASSED_VALIDATION'}
      ${siteProfiles[1]} | ${'FAILED_VALIDATION'}
    `("set the profile's status in the cache", ({ siteProfile, status }) => {
      const mockData = {
        project: {
          siteProfiles: {
            nodes: [siteProfile],
          },
        },
      };
      const mockStore = {
        readQuery: () => mockData,
        writeFragment: jest.fn(),
      };

      updateSiteProfilesStatuses({
        fullPath: 'full/path',
        normalizedTargetUrl: siteProfile.normalizedTargetUrl,
        status,
        store: mockStore,
      });

      expect(mockStore.writeFragment).toHaveBeenCalledWith({
        id: `DastSiteProfile:${siteProfile.id}`,
        fragment: gql`
          fragment profile on DastSiteProfile {
            validationStatus
            __typename
          }
        `,
        data: {
          validationStatus: status,
          __typename: 'DastSiteProfile',
        },
      });
    });
  });
});
