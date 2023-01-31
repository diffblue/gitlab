import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createClient from '~/lib/graphql';
import { createCustomersDotClient } from 'ee/lib/customers_dot_graphql';

Vue.use(VueApollo);

const gitlabClient = createClient();
const customersDotClient = createCustomersDotClient();

export default new VueApollo({
  defaultClient: createCustomersDotClient(),
  clients: {
    gitlabClient,
    customersDotClient,
  },
});
