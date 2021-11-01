import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import typeDefs from 'ee/vue_shared/purchase_flow/graphql/typedefs.graphql';
import createClient from '~/lib/graphql';
import { GITLAB_CLIENT, CUSTOMERSDOT_CLIENT } from './constants';
import { resolvers } from './graphql/resolvers';

Vue.use(VueApollo);

const gitlabClient = createClient(merge({}, resolvers, purchaseFlowResolvers), {
  typeDefs,
});

const customersDotClient = createClient(
  {},
  {
    path: '/-/customers_dot/proxy/graphql',
    useGet: true,
  },
);

export default new VueApollo({
  defaultClient: gitlabClient,
  clients: {
    [GITLAB_CLIENT]: gitlabClient,
    [CUSTOMERSDOT_CLIENT]: customersDotClient,
  },
});
