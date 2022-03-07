import { getGraphqlClient } from 'ee/geo_replicable/utils';

jest.mock('~/lib/graphql', () => ({
  ...jest.requireActual('~/lib/graphql'),
  __esModule: true,
  default: jest.fn().mockImplementation((_, { path }) => path),
}));

describe('GeoReplicable utils', () => {
  describe('getGraphqlClient', () => {
    describe.each`
      currentNodeId | targetNodeId | shouldReturnSpecificClient
      ${2}          | ${3}         | ${true}
      ${2}          | ${2}         | ${false}
      ${undefined}  | ${2}         | ${true}
      ${undefined}  | ${undefined} | ${false}
      ${2}          | ${undefined} | ${false}
    `(`geoNodeIds`, ({ currentNodeId, targetNodeId, shouldReturnSpecificClient }) => {
      it('returns the expected client', () => {
        const expectedGqClientPath = shouldReturnSpecificClient
          ? `/api/v4/geo/node_proxy/${targetNodeId}/graphql`
          : '/api/v4/geo/graphql';

        expect(getGraphqlClient(currentNodeId, targetNodeId)).toBe(expectedGqClientPath);
      });
    });
  });
});
