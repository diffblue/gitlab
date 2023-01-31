import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createCustomersDotClient } from 'ee/lib/customers_dot_graphql';

Vue.use(VueApollo);

const customersDotClient = createCustomersDotClient();

const apolloProvider = new VueApollo({
  defaultClient: customersDotClient,
});

export default apolloProvider;
