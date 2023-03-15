import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import resolvers from './resolvers/resolvers';
import typeDefs from './typedefs.graphql';

Vue.use(VueApollo);

export const typePolicies = {
  Query: {
    fields: {
      sharedData: {
        read(cachedData) {
          return (
            cachedData || {
              showDiscardChangesModal: false,
              formTouched: false,
              history: [],
              cachedPayload: {
                __typename: 'CachedPayload',
                profileType: '',
                mode: '',
              },
              resetAndClose: false,
              __typename: 'SharedData',
            }
          );
        },
      },
    },
  },
};

export const defaultClient = createDefaultClient(resolvers, {
  cacheConfig: { typePolicies },
  typeDefs,
});

export default new VueApollo({
  defaultClient,
});
