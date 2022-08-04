import dastProfilesMock from 'test_fixtures/graphql/on_demand_scans/graphql/dast_profiles.query.graphql.json';
import { removeProfile } from 'ee/on_demand_scans/graphql/cache_utils';

const [firstProfile, ...otherProfiles] = dastProfilesMock.data.project.pipelines.nodes;

describe('EE - On-demand Scans GraphQL CacheUtils', () => {
  describe('removeProfile', () => {
    it('removes the profile with the given id from the cache', () => {
      const mockQueryBody = { query: 'foo', variables: { foo: 'bar' } };
      const mockStore = {
        readQuery: () => dastProfilesMock.data,
        writeQuery: jest.fn(),
      };

      removeProfile({
        store: mockStore,
        queryBody: mockQueryBody,
        profileId: firstProfile.id,
      });

      expect(mockStore.writeQuery).toHaveBeenCalledWith({
        ...mockQueryBody,
        data: {
          project: {
            __typename: 'Project',
            id: dastProfilesMock.data.project.id,
            pipelines: {
              __typename: 'DastProfileConnection',
              nodes: otherProfiles,
              pageInfo: expect.any(Object),
            },
          },
        },
      });
    });
  });
});
