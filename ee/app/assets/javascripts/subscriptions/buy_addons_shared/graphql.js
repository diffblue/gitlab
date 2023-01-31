import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import purchaseFlowResolvers from 'ee/vue_shared/purchase_flow/graphql/resolvers';
import typeDefs from 'ee/vue_shared/purchase_flow/graphql/typedefs.graphql';
import createClient from '~/lib/graphql';
import { createCustomersDotClient } from 'ee/lib/customers_dot_graphql';
import typeDefsCDot from 'ee/subscriptions/buy_addons_shared/graphql/typedefs.graphql';
import { CUSTOMERSDOT_CLIENT, GITLAB_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import {
  customersDotResolvers,
  gitLabResolvers,
} from 'ee/subscriptions/buy_addons_shared/graphql/resolvers';

Vue.use(VueApollo);

const gitlabClient = createClient(merge({}, gitLabResolvers, purchaseFlowResolvers), {
  typeDefs,
});

const customersDotClient = createCustomersDotClient(customersDotResolvers, {
  typeDefs: typeDefsCDot,
});

export default new VueApollo({
  defaultClient: gitlabClient,
  clients: {
    [GITLAB_CLIENT]: gitlabClient,
    [CUSTOMERSDOT_CLIENT]: customersDotClient,
  },
});
