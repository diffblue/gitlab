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

const gitlabClient = createClient();

export default new VueApollo({
  defaultClient: customersDotClient,
  clients: {
    gitlabClient,
    customersDotClient,
  },
});
