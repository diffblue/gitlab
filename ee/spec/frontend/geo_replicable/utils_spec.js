import { getGraphqlClient } from 'ee/geo_replicable/utils';

jest.mock('~/lib/graphql', () => ({
  ...jest.requireActual('~/lib/graphql'),
  __esModule: true,
  default: jest.fn().mockImplementation((_, { path }) => path),
}));

describe('GeoReplicable utils', () => {
  describe('getGraphqlClient', () => {
    describe.each`
      currentSiteId | targetSiteId | shouldReturnSpecificClient
      ${2}          | ${3}         | ${true}
      ${2}          | ${2}         | ${false}
      ${undefined}  | ${2}         | ${true}
      ${undefined}  | ${undefined} | ${false}
      ${2}          | ${undefined} | ${false}
    `(`geoSiteIds`, ({ currentSiteId, targetSiteId, shouldReturnSpecificClient }) => {
      it('returns the expected client', () => {
        // geo/node_proxy to be renamed geo/site_proxy => https://gitlab.com/gitlab-org/gitlab/-/issues/396741
        const expectedGqClientPath = shouldReturnSpecificClient
          ? `/api/v4/geo/node_proxy/${targetSiteId}/graphql`
          : '/api/v4/geo/graphql';

        expect(getGraphqlClient(currentSiteId, targetSiteId)).toBe(expectedGqClientPath);
      });
    });
  });
});
