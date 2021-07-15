import apolloProvider from 'ee/subscriptions/buy_minutes/graphql';
import { writeInitialDataToApolloCache } from 'ee/subscriptions/buy_minutes/utils';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { mockNamespaces, mockParsedNamespaces } from './mock_data';

const DEFAULT_DATA = {
  groupData: mockNamespaces,
  namespaceId: mockParsedNamespaces[0].id,
  newUser: false,
  fullName: null,
  setupForCompany: false,
};

describe('utils', () => {
  beforeEach(() => {
    apolloProvider.clients.defaultClient.clearStore();
  });

  describe('#writeInitialDataToApolloCache', () => {
    describe('namespaces', () => {
      describe.each`
        namespaces        | parsedNamespaces        | throws
        ${'[]'}           | ${[]}                   | ${false}
        ${'null'}         | ${{}}                   | ${true}
        ${''}             | ${{}}                   | ${true}
        ${mockNamespaces} | ${mockParsedNamespaces} | ${false}
      `('parameter decoding', ({ namespaces, parsedNamespaces, throws }) => {
        it(`decodes ${namespaces} to ${parsedNamespaces}`, async () => {
          if (throws) {
            expect(() => {
              writeInitialDataToApolloCache(apolloProvider, { groupData: namespaces });
            }).toThrow();
          } else {
            writeInitialDataToApolloCache(apolloProvider, {
              ...DEFAULT_DATA,
              groupData: namespaces,
            });
            const sourceData = await apolloProvider.clients.defaultClient.query({
              query: stateQuery,
            });
            expect(sourceData.data.namespaces).toStrictEqual(parsedNamespaces);
          }
        });
      });
    });
  });
});
