import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import typeDefs from 'ee/vue_shared/purchase_flow/graphql/typedefs.graphql';
import createClient from '~/lib/graphql';
import { GITLAB_CLIENT, CUSTOMER_CLIENT } from './constants';
import { resolvers } from './graphql/resolvers';

Vue.use(VueApollo);

const gitlabClient = createClient(merge({}, resolvers, purchaseFlowResolvers), {
  typeDefs,
  assumeImmutableResults: true,
});
const customerClient = createClient(
  {},
  {
    path: '/-/customers_dot/proxy/graphql',
    useGet: true,
    assumeImmutableResults: true,
  },
);

export default new VueApollo({
  defaultClient: gitlabClient,
  clients: {
    [GITLAB_CLIENT]: gitlabClient,
    [CUSTOMER_CLIENT]: customerClient,
  },
});
