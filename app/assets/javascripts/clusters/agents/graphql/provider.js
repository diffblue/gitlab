import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import introspectionQueryResultData from './fragmentTypes.json';

Vue.use(VueApollo);

// We create a fragment matcher so that we can create a fragment from an interface
// Without this, Apollo throws a heuristic fragment matcher warning
const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

const defaultClient = createDefaultClient(
  {},
  {
    cacheConfig: {
      fragmentMatcher,
    },
  },
);

export default new VueApollo({
  defaultClient,
});
