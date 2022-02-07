import gql from 'graphql-tag';
import {
  appendToPreviousResult,
  removeProfile,
  dastProfilesDeleteResponse,
  updateSiteProfilesStatuses,
} from 'ee/security_configuration/dast_profiles/graphql/cache_utils';
import { siteProfiles } from '../mocks/mock_data';

describe('EE - DastProfiles GraphQL CacheUtils', () => {
  describe('appendToPreviousResult', () => {
    it.each(['siteProfiles', 'scannerProfiles'])(
      'appends new results to previous',
      (profileType) => {
        const previousResult = { project: { [profileType]: { nodes: ['foo'] } } };
        const fetchMoreResult = { project: { [profileType]: { nodes: ['bar'] } } };

        const expected = { project: { [profileType]: { nodes: ['foo', 'bar'] } } };
        const result = appendToPreviousResult(profileType)(previousResult, { fetchMoreResult });

        expect(result).toEqual(expected);
      },
    );
  });

  describe('removeProfile', () => {
    it.each(['foo', 'bar'])(
      'removes the profile with the given id from the cache',
      (profileType) => {
        const mockQueryBody = { query: 'foo', variables: { foo: 'bar' } };
        const mockProfiles = [{ id: 0 }, { id: 1 }];
        const mockData = {
          project: {
            [profileType]: {
              nodes: [mockProfiles[0], mockProfiles[1]],
            },
          },
        };
        const mockStore = {
          readQuery: () => mockData,
          writeQuery: jest.fn(),
        };

        removeProfile({
          store: mockStore,
          queryBody: mockQueryBody,
          profileId: mockProfiles[0].id,
          profileType,
        });

        expect(mockStore.writeQuery).toHaveBeenCalledWith({
          ...mockQueryBody,
          data: {
            project: {
              [profileType]: {
                nodes: [mockProfiles[1]],
              },
            },
          },
        });
      },
    );
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
