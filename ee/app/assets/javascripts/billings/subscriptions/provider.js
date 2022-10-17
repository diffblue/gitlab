import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createClient from '~/lib/graphql';

Vue.use(VueApollo);

const customersDotClient = createClient(
  {},
  {
    path: '/-/customers_dot/proxy/graphql',
    useGet: true,
  },
);

const apolloProvider = new VueApollo({
  defaultClient: customersDotClient,
});

export default apolloProvider;
